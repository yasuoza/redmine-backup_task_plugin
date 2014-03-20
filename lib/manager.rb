module Backup
  class Manager
    BACKUP_CONTENTS = %w{db/ files/ backup_information.yml}

    def pack
      # saving additional informations
      s = {}
      s[:db_version]         = "#{ActiveRecord::Migrator.current_version}"
      s[:backup_created_at]  = Time.now
      s[:redmine_version]    = Redmine::VERSION.to_s
      s[:tar_version]        = tar_version

      backup_dir = ENV['REDMINE_BACKUP_DIR'] || Rails.root.join('tmp')

      Dir.chdir(backup_dir)

      File.open("#{backup_dir}/backup_information.yml", "w+") do |file|
        file << s.to_yaml.gsub(/^---\n/,'')
      end

      # create archive
      print "Creating backup archive: #{s[:backup_created_at].to_i}_redmine_backup.tar ... "
      if Kernel.system('tar', '-cf', "#{s[:backup_created_at].to_i}_redmine_backup.tar", *BACKUP_CONTENTS)
        puts "done"
      else
        puts "failed"
      end
    end

    def cleanup
      print "Deleting tmp directories ... "
      if Kernel.system('rm', '-rf', *BACKUP_CONTENTS)
        puts "done"
      else
        puts "failed"
      end
    end

    def remove_old
      # delete backups
      print "Deleting old backups ... "
      keep_time = ENV['DEDMINE_BACKUP_KEEP_TIME'] || 0
      path = ENV['REDMINE_BACKUP_DIR'] || Rails.root.join('tmp')

      if keep_time > 0
        removed = 0
        file_list = Dir.glob(Rails.root.join(path, "*_redmine_backup.tar"))
        file_list.map! { |f| $1.to_i if f =~ /(\d+)_redmine_backup.tar/ }
        file_list.sort.each do |timestamp|
          if Time.at(timestamp) < (Time.now - keep_time)
            if Kernel.system(*%W(rm #{timestamp}_redmine_backup.tar))
              removed += 1
            end
          end
        end
        puts "done. (#{removed} removed)"
      else
        puts "skipping"
      end
    end

    def unpack
      Dir.chdir(ENV['REDMINE_BACKUP_DIR'] || Rails.root.join('tmp'))

      # check for existing backups in the backup dir
      file_list = Dir.glob("*_redmine_backup.tar").each.map { |f| f.split(/_/).first.to_i }
      puts "no backups found" if file_list.count == 0
      if file_list.count > 1 && ENV["BACKUP"].nil?
        puts "Found more than one backup, please specify which one you want to restore:"
        puts "rake redmine:backup:restore BACKUP=timestamp_of_backup"
        exit 1
      end

      tar_file = ENV["BACKUP"].nil? ? File.join("#{file_list.first}_redmine_backup.tar") : File.join(ENV["BACKUP"] + "_redmine_backup.tar")

      unless File.exists?(tar_file)
        puts "The specified backup doesn't exist!"
        exit 1
      end

      print "Unpacking backup ... "
      unless Kernel.system(*%W(tar -xf #{tar_file}))
        puts "failed"
        exit 1
      else
        puts "done"
      end

      settings = YAML.load_file("backup_information.yml")
      ENV["VERSION"] = "#{settings[:db_version]}" if settings[:db_version].to_i > 0

      # restoring mismatching backups can lead to unexpected problems
      if settings[:redmine_version] != Redmine::VERSION.to_s
        puts "Redmine version mismatch:"
        puts "  Your current Redmine version (#{Redmine::VERSION}) differs from the Redmine version in the backup!"
        puts "  You may need to run upgrade task. Refer to:"
        puts "  http://www.redmine.org/projects/redmine/wiki/RedmineUpgrade#Step-3-Perform-the-upgrade"
      end
    end

    def tar_version
      tar_version = `tar --version`
      tar_version.split("\n").first
    end
  end
end
