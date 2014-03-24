module Backup
  class Files
    attr_reader :app_uploads_dir, :backup_uploads_dir, :backup_dir

    def initialize
      @app_uploads_dir    = File.realpath(Attachment.storage_path)
      @backup_dir         = ENV['REDMINE_BACKUP_DIR'] || Rails.root.join('tmp', 'backups')
      @backup_uploads_dir = File.join(@backup_dir, 'files')
    end

    # Copy uploads from files to tmp/files
    def dump
      FileUtils.mkdir_p(backup_uploads_dir)
      FileUtils.cp_r(app_uploads_dir, backup_dir)
    end

    def restore
      backup_existing_uploads_dir

      FileUtils.cp_r(backup_uploads_dir, app_uploads_dir)
    end

    def backup_existing_uploads_dir
      timestamped_uploads_path = File.join(app_uploads_dir, '..', "files.#{Time.now.to_i}")
      if File.exists?(app_uploads_dir)
        FileUtils.mv(app_uploads_dir, timestamped_uploads_path)
      end
    end
  end
end
