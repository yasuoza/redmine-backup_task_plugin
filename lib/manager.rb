require 'open3'

module Backup
  class Manager
    BACKUP_CONTENTS = %w{db/ files/ backup_information.yml}

    def pack
      # saving additional informations
      s = {}
      s[:db_version]         = "#{ActiveRecord::Migrator.current_version}"
      s[:backup_created_at]  = Time.now
      s[:gitlab_version]     = Redmine::VERSION
      s[:tar_version]        = tar_version

      Dir.chdir(Setting.plugin_redmine_backup_supporter[:redmine_backup_dir])

      File.open("#{Setting.plugin_redmine_backup_supporter[:redmine_backup_dir]}/backup_information.yml", "w+") do |file|
        file << s.to_yaml.gsub(/^---\n/,'')
      end

      # create archive
      print "Creating backup archive: #{s[:backup_created_at].to_i}_gitlab_backup.tar ... "
      if Kernel.system('tar', '-cf', "#{s[:backup_created_at].to_i}_gitlab_backup.tar", *BACKUP_CONTENTS)
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
      keep_time = Setting.plugin_redmine_backup_supporter[:redmine_backup_keep_time]
      path = Setting.plugin_redmine_backup_supporter[:redmine_backup_dir]

      if keep_time > 0
        removed = 0
        file_list = Dir.glob(Rails.root.join(path, "*_gitlab_backup.tar"))
        file_list.map! { |f| $1.to_i if f =~ /(\d+)_gitlab_backup.tar/ }
        file_list.sort.each do |timestamp|
          if Time.at(timestamp) < (Time.now - keep_time)
            if Kernel.system(*%W(rm #{timestamp}_gitlab_backup.tar))
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
      Dir.chdir(Gitlab.config.backup.path)

      # check for existing backups in the backup dir
      file_list = Dir.glob("*_gitlab_backup.tar").each.map { |f| f.split(/_/).first.to_i }
      puts "no backups found" if file_list.count == 0
      if file_list.count > 1 && ENV["BACKUP"].nil?
        puts "Found more than one backup, please specify which one you want to restore:"
        puts "rake gitlab:backup:restore BACKUP=timestamp_of_backup"
        exit 1
      end

      tar_file = ENV["BACKUP"].nil? ? File.join("#{file_list.first}_gitlab_backup.tar") : File.join(ENV["BACKUP"] + "_gitlab_backup.tar")

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
      if settings[:gitlab_version] != Redmine::VERSION
        puts "GitLab version mismatch:"
        puts "  Your current GitLab version (#{Redmine::VERSION}) differs from the GitLab version in the backup!"
        puts "  Please switch to the following version and try again:"
        puts "  version: #{settings[:gitlab_version]}"
        puts
        puts "Hint: git checkout v#{settings[:gitlab_version]}"
        exit 1
      end
    end

    def tar_version
      vars = { 'PWD' => Dir.pwd }
      # cmd_output = ""
      # cmd_status = 0
      tar_version = `tar --version`
      # tar_version, _ = Open3.popen3(vars, %W(tar --version)) do |stdin, stdout, stderr, wait_thr|
        # cmd_output << stdout.read
        # cmd_output << stderr.read
        # cmd_status = wait_thr.value.exitstatus
      # end
      tar_version.split("\n").first
    end
  end
end
