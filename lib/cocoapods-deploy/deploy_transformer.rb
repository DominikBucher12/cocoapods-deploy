module Pod
  class DeployTransformer

    attr_accessor :lockfile
    attr_accessor :sandbox
    attr_accessor :metadata

    def initialize(lockfile, sandbox)
      @lockfile = lockfile
      @sandbox = sandbox
      @metadata = Source::Metadata.new({'prefix_lengths' => [1, 1, 1]})
    end

    def transform_podfile(podfile)
      internal_hash = podfile.to_hash
      new_hash = transform_internal_hash(internal_hash)

      Podfile.from_hash(new_hash, podfile.defined_in_file)
    end

    def transform_dependency_name(name)
      dependency_hash = transform_dependency(name)
      parse_dependency(dependency_hash)
    end

    private

    def transform_internal_hash(hash)
      targets = hash["target_definitions"]
      targets.map do |target|
        transform_target_definition_hash(target)
      end if targets

      hash
    end

    def transform_target_definition_hash(hash)
      dependencies = hash["dependencies"]
      hash["dependencies"] = dependencies.map do |dep|
        transform_dependency(dep)
      end if dependencies

      #Duplicate this to prevent infinte loop
      dependencies = hash["dependencies"]
      dependencies.dup.map do |dep|
        podspec_dependencies = collect_podspec_dependencies(dep)
        hash["dependencies"].concat(podspec_dependencies) if podspec_dependencies
      end if dependencies && @sandbox

      children = hash["children"]
      hash["children"] = children.map do |target|
        transform_target_definition_hash(target)
      end if children

      hash
    end

    def parse_dependency(name_or_hash)
      if name_or_hash.is_a?(Hash)
        name = name_or_hash.keys.first
        requirements = name_or_hash.values.first
        Dependency.new(name, *requirements)
      else
        Dependency.new(name_or_hash)
      end
    end

    def podspec_url(pod, version)
      path_fragment = metadata.path_fragment(pod)
      "{root-url}/#{path_fragment}/#{version}/#{pod}"
    end

    def collect_podspec_dependencies(name_or_hash)
      dependency = parse_dependency(name_or_hash)
      specification = @sandbox.specification(dependency.root_name)

      dependencies = specification.dependencies.map do |dep|
        begin
          transform_dependency(dep.name)
        rescue Informative
          nil
        end
      end if specification

      dependencies.select { |dep|
        dep != nil
      }
    end

    def transform_dependency(name_or_hash)
      dependency = parse_dependency(name_or_hash)
      pod = dependency.name
      checkout_options = @lockfile.checkout_options_for_pod_named(pod)

      unless checkout_options
        root_pod = dependency.root_name
        version = @lockfile.version(pod)
        raise Informative, "Missing dependency \"#{pod}\" in Lockfile please run `pod install` or `pod update`." unless version

        ({ "#{pod}" => [{ :podspec => podspec_url(root_pod, version) }] })
      else
        ({ "#{pod}" => [checkout_options] })
      end
    end
  end
end
