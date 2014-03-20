require_relative '../database'
require_relative '../files'
require_relative '../manager'

namespace :redmine do
  namespace :backup do
    desc 'Create redmine backup'
    task create: :environment do
      Rake::Task["backup:db:create"].invoke
      Rake::Task["backup:files:create"].invoke

      backup = Backup::Manager.new
      backup.pack
      backup.cleanup
      backup.remove_old
    end

    desc "Restore a previously created backup"
    task restore: :environment do
      backup = Backup::Manager.new
      backup.unpack

      Rake::Task["backup:db:restore"].invoke
      Rake::Task["backup:files:restore"].invoke

      backup.cleanup
    end

    namespace :db do
      task create: :environment do
        puts "Dumping database ... "
        Backup::Database.new.dump
        puts "done"
      end

      task restore: :environment do
        puts "Restoring database ... "
        Backup::Database.new.restore
        puts "done"
      end
    end

    namespace :files do
      task create: :environment do
        puts "Dumping uploads ... "
        Backup::Files.new.dump
        puts "done"
      end

      task restore: :environment do
        puts "Restoring uploads ... "
        Backup::Files.new.restore
        puts "done"
      end
    end
  end
end
