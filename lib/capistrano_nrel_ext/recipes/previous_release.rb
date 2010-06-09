Capistrano::Configuration.instance(true).load do
  set(:previous_release_name) { if(previous_release) then File.basename(previous_release) else nil end }
end
