require 'rake'
require 'fileutils'
require File.join(File.dirname(__FILE__), 'bin', 'yadr', 'vundle')

desc "Hook our dotfiles into system-standard positions."
task :install => [:submodule_init, :submodules] do
  puts
  puts "======================================================"
  puts "Welcome to YADR Installation."
  puts "======================================================"
  puts

  # this has all the runcoms from this directory.
  install_files(Dir.glob('git/*')) if want_to_install?('git configs (color, aliases)')
  install_files(Dir.glob('ctags/*')) if want_to_install?('ctags config (better js/ruby support)')
  install_files(Dir.glob('tmux/*')) if want_to_install?('tmux config')
  install_files(Dir.glob('vimify/*')) if want_to_install?('vimification of command line tools')
  install_files(Dir.glob('python/*')) if want_to_install?('python config')
  link_file('spacemacs', "#{ENV["HOME"]}/.emacs.d/") if want_to_install?('emacs config')
  link_file('spacemacs_config', "#{ENV["HOME"]}/.spacemacs") if want_to_install?('emacs config')
  link_file('i3', "#{ENV["HOME"]}/.config/i3") if want_to_install?('i3 config')
  link_file('i3status', "#{ENV["HOME"]}/.config/i3status") if want_to_install?('i3 config')
  if want_to_install?('vim configuration (highly recommended)')
    install_files(Dir.glob('{vim,vimrc}'))
    Rake::Task["install_vundle"].execute
  end

  Rake::Task["install_prezto"].execute

  install_fonts

  run_bundle_config

  success_msg("installed")
end

task :install_prezto do
  if want_to_install?('zsh enhancements & prezto')
    install_prezto
  end
end

desc 'Updates the installation'
task :update do
  Rake::Task["vundle_migration"].execute if needs_migration_to_vundle?
  Rake::Task["install"].execute
  #TODO: for now, we do the same as install. But it would be nice
  #not to clobber zsh files
end

task :submodule_init do
  unless ENV["SKIP_SUBMODULES"]
    run %{ git submodule update --init --recursive }
  end
end

desc "Init and update submodules."
task :submodules do
  unless ENV["SKIP_SUBMODULES"]
    puts "======================================================"
    puts "Downloading YADR submodules...please wait"
    puts "======================================================"

    run %{
      cd $HOME/.yadr
      git submodule update --recursive
      git clean -df
    }
    puts
  end
end

desc "Performs migration from pathogen to vundle"
task :vundle_migration do
  puts "======================================================"
  puts "Migrating from pathogen to vundle vim plugin manager. "
  puts "This will move the old .vim/bundle directory to"
  puts ".vim/bundle.old and replacing all your vim plugins with"
  puts "the standard set of plugins. You will then be able to "
  puts "manage your vim's plugin configuration by editing the "
  puts "file .vim/vundles.vim"
  puts "======================================================"

  Dir.glob(File.join('vim', 'bundle','**')) do |sub_path|
    run %{git config -f #{File.join('.git', 'config')} --remove-section submodule.#{sub_path}}
    # `git rm --cached #{sub_path}`
    FileUtils.rm_rf(File.join('.git', 'modules', sub_path))
  end
  FileUtils.mv(File.join('vim','bundle'), File.join('vim', 'bundle.old'))
end

desc "Runs Vundle installer in a clean vim environment"
task :install_vundle do
  puts "======================================================"
  puts "Installing and updating vundles."
  puts "The installer will now proceed to run PluginInstall to install vundles."
  puts "======================================================"

  puts ""

  vundle_path = File.join('vim','bundle', 'vundle')
  unless File.exists?(vundle_path)
    run %{
      cd $HOME/.yadr
      git clone https://github.com/gmarik/vundle.git #{vundle_path}
    }
  end

  Vundle::update_vundle
end

task :default => 'install'


private
def run(cmd)
  puts "[Running] #{cmd}"
  `#{cmd}` unless ENV['DEBUG']
end

def number_of_cores
  if RUBY_PLATFORM.downcase.include?("darwin")
    cores = run %{ sysctl -n hw.ncpu }
  else
    cores = run %{ nproc }
  end
  puts
  cores.to_i
end

def run_bundle_config
  return unless system("which bundle")

  bundler_jobs = number_of_cores - 1
  puts "======================================================"
  puts "Configuring Bundlers for parallel gem installation"
  puts "======================================================"
  run %{ bundle config --global jobs #{bundler_jobs} }
  puts
end

def install_rvm_binstubs
  puts "======================================================"
  puts "Installing RVM Bundler support. Never have to type"
  puts "bundle exec again! Please use bundle --binstubs and RVM"
  puts "will automatically use those bins after cd'ing into dir."
  puts "======================================================"
  run %{ chmod +x $rvm_path/hooks/after_cd_bundler }
  puts
end

def install_fonts
  puts "======================================================"
  puts "Installing patched fonts for Powerline/Lightline."
  puts "======================================================"
  run %{ cp -f $HOME/.yadr/fonts/* $HOME/Library/Fonts } if RUBY_PLATFORM.downcase.include?("darwin")
  run %{ mkdir -p ~/.fonts && cp ~/.yadr/fonts/* ~/.fonts && fc-cache -vf ~/.fonts } if RUBY_PLATFORM.downcase.include?("linux")
  puts
end

def ask(message, values)
  puts message
  while true
    values.each_with_index { |val, idx| puts " #{idx+1}. #{val}" }
    selection = STDIN.gets.chomp
    if (Float(selection)==nil rescue true) || selection.to_i < 0 || selection.to_i > values.size+1
      puts "ERROR: Invalid selection.\n\n"
    else
      break
    end
  end
  selection = selection.to_i-1
  values[selection]
end

def install_prezto
  puts
  puts "Installing Prezto (ZSH Enhancements)..."

  run %{ ln -nfs "$HOME/.yadr/zsh/prezto" "${ZDOTDIR:-$HOME}/.zprezto" }

  # The prezto runcoms are only going to be installed if zprezto has never been installed
  install_files(Dir.glob('zsh/prezto/runcoms/z*'), :symlink)

  puts
  puts "Overriding prezto ~/.zpreztorc with YADR's zpreztorc to enable additional modules..."
  run %{ ln -nfs "$HOME/.yadr/zsh/prezto-override/zpreztorc" "${ZDOTDIR:-$HOME}/.zpreztorc" }

  puts
  puts "Creating directories for your customizations"
  run %{ mkdir -p $HOME/.zsh.before }
  run %{ mkdir -p $HOME/.zsh.after }
  run %{ mkdir -p $HOME/.zsh.prompts }

  if ENV["SHELL"].include? 'zsh' then
    puts "Zsh is already configured as your shell of choice. Restart your session to load the new settings"
  else
    puts "Setting zsh as your default shell"
    if File.exists?("/usr/local/bin/zsh")
      if File.readlines("/private/etc/shells").grep("/usr/local/bin/zsh").empty?
        puts "Adding zsh to standard shell list"
        run %{ echo "/usr/local/bin/zsh" | sudo tee -a /private/etc/shells }
      end
      run %{ chsh -s /usr/local/bin/zsh }
    else
      run %{ chsh -s /bin/zsh }
    end
  end
end

def want_to_install? (section)
  if ENV["ASK"]=="true"
    puts "Would you like to install configuration files for: #{section}? [y]es, [n]o"
    STDIN.gets.chomp == 'y'
  else
    true
  end
end

def install_files(files, method = :symlink)
  files.each do |f|
    file = f.split('/').last
    source = "#{ENV["PWD"]}/#{f}"
    target = "#{ENV["HOME"]}/.#{file}"

    link_file(source, target, method)
  end
end

def link_file(source, target, method = :symlink)
    puts "======================#{file}=============================="
    puts "Source: #{source}"
    puts "Target: #{target}"

    if File.exists?(target) && (!File.symlink?(target) || (File.symlink?(target) && File.readlink(target) != source))
      puts "[Overwriting] #{target}...leaving original at #{target}.backup..."
      run %{ mv "$HOME/.#{file}" "$HOME/.#{file}.backup" }
    end

    if method == :symlink
      run %{ ln -nfs "#{source}" "#{target}" }
    else
      run %{ cp -f "#{source}" "#{target}" }
    end

    # Temporary solution until we find a way to allow customization
    # This modifies zshrc to load all of yadr's zsh extensions.
    # Eventually yadr's zsh extensions should be ported to prezto modules.
    if file == 'zshrc'
      File.open(target, 'a') do |zshrc|
        zshrc.puts('for config_file ($HOME/.yadr/zsh/*.zsh) source $config_file')
      end
    end

    puts "=========================================================="
    puts
end

def needs_migration_to_vundle?
  File.exists? File.join('vim', 'bundle', 'tpope-vim-pathogen')
end


def list_vim_submodules
  result=`git submodule -q foreach 'echo $name"||"\`git remote -v | awk "END{print \\\\\$2}"\`'`.select{ |line| line =~ /^vim.bundle/ }.map{ |line| line.split('||') }
  Hash[*result.flatten]
end

def apply_theme_to_iterm_profile_idx(index, color_scheme_path)
  values = Array.new
  16.times { |i| values << "Ansi #{i} Color" }
  values << ['Background Color', 'Bold Color', 'Cursor Color', 'Cursor Text Color', 'Foreground Color', 'Selected Text Color', 'Selection Color']
  values.flatten.each { |entry| run %{ /usr/libexec/PlistBuddy -c "Delete :'New Bookmarks':#{index}:'#{entry}'" ~/Library/Preferences/com.googlecode.iterm2.plist } }

  run %{ /usr/libexec/PlistBuddy -c "Merge '#{color_scheme_path}' :'New Bookmarks':#{index}" ~/Library/Preferences/com.googlecode.iterm2.plist }
  run %{ defaults read com.googlecode.iterm2 }
end

def success_msg(action)
  puts ""
  puts "   _     _           _         "
  puts "  | |   | |         | |        "
  puts "  | |___| |_____  __| | ____   "
  puts "  |_____  (____ |/ _  |/ ___)  "
  puts "   _____| / ___ ( (_| | |      "
  puts "  (_______\_____|\____|_|      "
  puts ""
  puts "YADR has been #{action}. Please restart your terminal and vim."
end
