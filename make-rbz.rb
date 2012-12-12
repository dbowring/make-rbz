# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
    
require 'optparse'

REPO_NAME = File.basename(File.expand_path('.'))
MAKE_RBZ_VERSION = '1.0.3'

###############################################################################
# Begin Interface Definitions
###############################################################################
class BaseRBZMaker
    attr_accessor :source_directory
    attr_reader :output_directory, :output_name, :ignore
    attr_writer :verbose, :force_overwrite, :strict

    FILE_NAME_FORBIDDEN = /[\<\>\:\"\|\?\*\t\r\n]/
    ROOT_FILEPATH = /^((?:[a-zA-Z]\:)?\/)/


    def self.setup()
        begin
            require 'rubygems'
        rescue => e
            puts "Error - rubygems required but failed to load"
            raise e
        end
    end
    def initialize()
        @output_directory = '.'
        @output_name = nil
        @source_directory = 'src'
        @force_overwrite = false
        @strict = true
        @ignore = []
    end

    def make_output_path()
        File.makedirs(output_directory)
    end

    def zipped_path(path)
        return path.sub(source_directory + '/', '')
    end

    def source_files()
        files = Dir[File.join(source_directory, '**', '**')]

        files = files.reject() {|f|
            ignore.map() {|p|
                File.fnmatch(p, f)
            }.any?
        } unless ignore.length.zero?

        return files
    end

    def path()
        return File.join(output_directory, output_name)
    end

    def puts(*args)
        super(*args) if verbose?
    end
    def print(*args)
        super(*args) if verbose?
    end

    def clean_path(path)
        return path.gsub(FILE_NAME_FORBIDDEN, '')
    end
    def output_directory=(path)
        @output_directory = clean_path(path.gsub('\\', '/'))
    end

    def output_name=(filename)
        if strict? && !output_name.nil?
            abort('Abort: Output Filename set multiple times. Use --no-strict to override')
        end

        filename = filename.gsub('\\', '/')
        if filename.include?('/')
            # Filename changes output directory
            if strict?
                abort('Abort: Output Filename would change directory. Use --no-strict to override')
            end
            if ROOT_FILEPATH.match(filname)
                output_directory = File.dirname(filename)
            else
                output_directory = File.join(output_directory, File.dirname(filename))
            end
        end

        filename = File.basename(filename)
        if File.extname(filename).downcase() != '.rbz'
            filename += '.rbz'
        end
        @output_name = filename
    end

    def also_ignore(types)
        @ignore = (@ignore + types).uniq
    end

    def validate()
        if output_name.length.zero?
            abort('Abort : Invalid Output Filename (Zero Length)')
        end

        if !force_overwrite? && File.exists?(path)
            abort("Abort : Output File already exists (use --force to overwrite)\n#{path}")
        end

        if !File.directory?(source_directory)
            abort("Abort : source directory does not exist")
        end
    end

    def verbose?()
        return @verbose
    end
    def force_overwrite?()
        return @force_overwrite
    end
    def strict?()
        return @strict
    end

    def run()
        abort('Not Implemented....Exiting.')
    end
end

class RBZMaker_1_9 < BaseRBZMaker
    def self.setup()
        super()
        begin
            require 'zip/zip'
        rescue => e
            abort("Error - zip/zip required but failed to load (gem install rubyzip)")
        end
    end

    def run()
        Zip::ZipOutputStream.open(path) {|zip|
            for file in source_files
                puts file
                entry = Zip::ZipEntry.new("", zipped_path(file))
                entry.gather_fileinfo_from_srcpath(file)
                zip.put_next_entry(entry, nil, nil, Zip::ZipEntry::DEFLATED, Zlib::BEST_COMPRESSION)
                entry.get_input_stream { |is| IOExtras.copy_stream(zip, is) }
            end
        }
    end
end

class RBZMaker_1_8 < BaseRBZMaker
    def self.setup()
        super()
        begin
            require 'zip/zip'
        rescue => e
            abort("Error - zip/zip required but failed to load (gem install rubyzip2)")
        end
    end

    def run()
        Zip::ZipOutputStream.open(path) {|zip|
            for file in source_files
                puts file
                entry = Zip::ZipEntry.new("", zipped_path(file))
                entry.gather_fileinfo_from_srcpath(file)
                zip.put_next_entry(entry, Zlib::BEST_COMPRESSION)
                entry.get_input_stream { |is| IOExtras.copy_stream(zip, is) }
            end
        }
    end

end


if defined?(RUBY_VERSION)
    a, b, c = RUBY_VERSION.split('.')
    if a == '1'
        if b == '8'
            RBZMaker = RBZMaker_1_8
        elsif b == '9'
            RBZMaker = RBZMaker_1_9
        else
            abort('Unsupported version #{RUBY_VERSION}')
        end
    else
        abort('Abort : Unknown Environment #{RUBY_VERSION}')
    end
else
    abort('Abort : Unknown Environment')
end
RBZMaker.setup()


###############################################################################
# End Interface definitions
###############################################################################




interface = RBZMaker.new()

OptionParser.new() {|opts|
    opts.banner = "Usage : ruby #{File.basename(__FILE__)} [OPTIONS]"

    opts.on(:OPTIONAL, '-v', '--[no-]verbose', 'Run Verbosely') {|bool|
        interface.verbose = bool
    }

    opts.on(:OPTIONAL, '-t', '--[no-]strict', 'Run in strict mode') {|bool|
        interface.strict = bool
    }
    opts.on(:OPTIONAL, '-f', '--[no-]force', 'Force file overwrites') {|bool|
        interface.force_overwrite = bool
    }

    opts.on('-o', '--outname', '=NAME', 'Set Output File Name') {|name|
        interface.output_name = name
    }
    opts.on('-p', '--outpath', '=PATH', 'Set Output File Path') {|path|
        interface.output_directory = path
    }
    opts.on('-s', '--source', '=PATH', 'Set Source Directory Path') {|path|
        interface.source_directory = path
    }

    opts.on('-r', '--read-stdin', 'Set File name from STDIN') {
            abort('Abort : Cannot read from STDIN') if STDIN.tty?
        interface.output_name = STDIN.read().strip()
    }
    opts.on('-i', '--ignore', '=PATTERNS', Array, 'Ignore files matching glob pattern') {|patterns|
        interface.also_ignore(patterns)
    }

}.parse!

if interface.output_name.nil?
    interface.output_name = REPO_NAME
end

interface.validate()
interface.run()

