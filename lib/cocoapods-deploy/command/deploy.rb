# - Patch Lockfile to store URLs
# - Use the data in deploy
module Pod
  class Command
    class Deploy < Command

      include ProjectDirectory

      self.summary = 'Install project dependencies to Podfile.lock versions without pulling down full podspec repo.'

      self.description = <<-DESC
        Install project dependencies to Podfile.lock versions without pulling down full podspec repo.
      DESC

      # This method sets up the environment to be optimised
      # for CocoaPod Deployment.
      #
      # Turning off things like repo cloning, clean-up and statistics.
      def setup_environment
        # Disable Cocoapods Stats - Due to
        # https://github.com/CocoaPods/cocoapods-stats/issues/28
        ENV['COCOAPODS_DISABLE_STATS'] = "1"
      end

      # Verify the environment is ready for deployment
      # i.e Do we have a podfile and lockfile.
      def verify_environment
        verify_podfile_exists!
        verify_lockfile_exists!
      end

      # This prepares the Podfile and Lockfile for deployment
      # by transforming Repo depedencies to Poddpec based dependencies
      # and making sure we have eveything we need for Subspecs which
      # typially don't work with Podspec based depedencies.
      def transform_podfile
        transformer = DeployTransformer.new(config.lockfile, config.sandbox)
        transformer.transform_podfile(config.podfile)
      end

      # Applies patch to resolver as it needs help being pointed to use the
      # local podspecs due to limitations in CocoaPods. We may be able to remove
      # this in the future.
      #
      # In the future passing the lockfile into the resolve is hacked
      # potentially we could have a special deploy subclass.
      #
      def apply_resolver_patch
        Resolver.class_eval do

          def find_cached_set(dependency)
            name = dependency.root_name

            unless cached_sets[name]
              spec = sandbox.specification(name)
              set = Specification::Set::External.new(spec)
              cached_sets[name] = set
              unless set
                raise Molinillo::NoSuchDependencyError.new(dependency) # rubocop:disable Style/RaiseArgs
              end
            end

            cached_sets[name]
          end

          def dependencies_for(specification)
            dependencies = specification.all_dependencies.select { |dep|
              Config.instance.lockfile.version(dep.root_name) != nil
            }

            dependencies.map do |dependency|
              if dependency.root_name == Specification.root_name(specification.name)
                dependency.dup.tap { |d| d.specific_version = specification.version }
              else
                dependency
              end
            end
          end
        end
      end

      # Applies patch to external sources to add a no_validate option which
      # can be used to disable validation of downloaded podspecs. A normal install
      # doesn't validate the podspecs of non-external pods even though certain
      # podspecs are not entirely valid (for example an invalid license file type).
      # This would mean the normal install command can install certain pods that deploy
      # doesn't because of the validation. This patch makes sure validation doesn't
      # happen when deploy is being used.
      #
      def apply_external_sources_patch
        ExternalSources::AbstractExternalSource.class_eval do
          attr_accessor :no_validate

          old_validate_podspec = instance_method(:validate_podspec)

          def validate_podspec(podspec)
            return if no_validate
            old_validate_podspec(podspec)
          end
        end
      end

      # Installs required sources for lockfile - TODO: Simplify code
      def install_sources_for_lockfile
        config.lockfile.pod_names.each do |pod|
          install_sources_for_pod(pod)
        end
      end

      # Installs required sources for pod.
      def install_sources_for_pod(pod)
        transformer = DeployTransformer.new(config.lockfile, config.sandbox)
        dep = transformer.transform_dependency_name(pod)

        downloader = DeployDownloader.new(dep)
        downloader.download(config)
      end

      # Triggers the CocoaPods install process
      def install(podfile)
        installer = DeployInstaller.new(config.sandbox, podfile, nil)

        # Disable updating of the CocoaPods Repo since we are directly
        # deploying using Podspecs
        installer.repo_update = false

        # Disable cleaning of the source file since we are deploying
        # and we don't need to keep things clean.
        installer.installation_options.clean = false

        installer.install!
      end

      def run
        setup_environment
        verify_environment

        apply_resolver_patch
        apply_external_sources_patch

        install_sources_for_lockfile
        install(transform_podfile)
      end
    end
  end
end
