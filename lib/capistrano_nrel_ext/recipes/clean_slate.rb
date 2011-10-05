Capistrano::Configuration.instance(true).load do
  #
  # Tasks
  #
  namespace :deploy do
    task :finalize_update, :except => { :no_release => true } do
      run "chmod -R g+w #{latest_release}" if fetch(:group_writable, true)
    end

    # Kill any default tasks we don't want at all.
    [:start, :stop, :restart, :migrate].each do |default_task|
      desc <<-DESC
        Default task overriden to do nothing.
      DESC
      task default_task do 
        # Do nothing
      end
    end
  end
end
