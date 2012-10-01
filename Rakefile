require 'rake'
require 'rake/testtask'
require 'rake/version_task'
require 'rubygems/gem_runner'
require 'rubygems/package_task'

def gemspec
  @gemspec ||= Gem::Specification.load('mini_aether.gemspec')
end

Rake::TestTask.new do |t|
  t.pattern = 'test/**/*_test.rb'
  t.libs.push 'test'
end

desc 'Run the tests'
task :default => :test

Gem::PackageTask.new(gemspec) do |p|
  p.need_tar = true
  p.gem_spec = gemspec
end

Rake::VersionTask.new do |t|
  t.with_git_tag = true
end

if Version.current.prerelease?
  orig_version = gemspec.version
  release_version = Version.current.bump!
  gemspec.version = release_version
  begin
    namespace :release do
      pkg = Gem::PackageTask.new(gemspec) do |p|
        p.need_tar = true
        p.gem_spec = gemspec
      end

      task :push => :gem do
        gem_file = File.basename gemspec.cache_file
        gem_path = File.join pkg.package_dir, gem_file
        Gem::GemRunner.new.run(['push', gem_path])
      end
    end
  ensure
    gemspec.version = orig_version
  end
  
  desc "Release version #{release_version} and push to rubygems.org"
  task :release => [:test, 'version:bump'] do
    Rake::Task['release:push'].invoke
    Rake::Task['version:bump:pre'].invoke
  end
end

