MiniAether
----------

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

Tests
=====

    rake test

Note: the unit tests download artifacts from the Maven central
repository into temp files and into `~/.m2/repository`.
