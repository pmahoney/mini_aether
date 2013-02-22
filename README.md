MiniAether [![Build Status][travis-img]][travis-ci]
----------

[travis-img]: https://api.travis-ci.org/pmahoney/mini_aether.png
[travis-ci]: https://travis-ci.org/pmahoney/mini_aether

JRuby wrapper around some parts of
[Aether](http://eclipse.org/aether/), the library underlying the
[Maven](http://maven.apache.org/) build and dependency management
tool.

* Bootstraps itself by downloading Aether components directly from the
  Maven Central repository.
* Installs JARs into the standard Maven location `~/.m2/repository`.
* Loads Aether libs in separate JRuby with own classloader to avoid
  contaminating the primary classloader.

I feel that JRuby/maven/rubygems integration is lacking in many areas.
There are various attempts to improve this.  See
[JBundler](https://github.com/mkristian/jbundler) and
[LockJar](https://github.com/mguymon/lock_jar) for example.  So I'm
not sure what role MiniAether will play, if any.

    require 'mini_aether'

    MiniAether.setup do
      group 'org.sonatype.aether' do
        version '1.13.1' do
          jar 'aether-api'
          jar 'aether-impl'
        end
      end

      jar 'com.ning:async-http-client:1.6.5'

      # alternate syntax
      dep(:group_id => 'org.slf4j',
          :artifact_id => 'slf4j-api',
          :version => '1.6.2',
          :extension => 'jar')  # 'jar' is the default if none is given

      group 'org.codehaus.plexus' do
        jar 'plexus-utils:2.0.6'
      end
    end

At this point, all those jars and their dependencies will be loaded
into the current JRuby.

Convenience `require_aether`
===========================

An experimental convenience method, possibly best used in an `irb` session:

    > require 'mini_aether/require'
    > require_aether 'org.slf4j:slf4j-api:1.7.2'
    > require_aether 'com.example:artifact:1.0', :source => 'http://maven.example.com/'

Tests
=====

    rake test

Note: the unit tests download artifacts from the Maven central
repository into temp files and into `~/.m2/repository`.
