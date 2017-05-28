module Pod

    # - Apply patch to sandbox
    # - Both work together to record URI of ext pod
    # - deploy transformer should use this data
    # - Help people upgrade to 0.1 of cocoapods-deploy

    Sandbox.class_eval do

        def external_podspecs
            @external_podspecs
        end

        def store_external_podspec(name, url)
            UI.message("store #{name} and #{url}")
            @external_podspecs ||= {}
            @external_podspecs[name] = url
        end
    end

    Installer.class_eval do

        def apply_lockfile_patch

            ExternalSources::DownloaderSource.class_eval do
                def pre_download(sandbox)

                    # - Call original and just apply the store section afterwards

                    strategy = Downloader.strategy_from_options(params)
                    options = params.dup
                    url = options.delete(strategy)

                    title = "Pre-downloading: `#{name}` #{description}"
                    UI.titled_section(title,  :verbose_prefix => '-> ') do
                      target = sandbox.pod_dir(name)
                      download_result = Downloader.download(download_request, target, :can_cache => can_cache)
                      spec = download_result.spec

                      raise Informative, "Unable to find a specification for '#{name}'." unless spec

                      store_podspec(sandbox, spec)
                      sandbox.store_external_podspec(name, url)
                      sandbox.store_pre_downloaded_pod(name)
                      sandbox.store_checkout_source(name, download_result.checkout_options)
                    end
              end
            end

            Lockfile.class_eval do
                def self.generate(podfile, specs, checkout_options, podspecs)
                    hash = {
                      'PODS'             => generate_pods_data(specs),
                      'DEPENDENCIES'     => generate_dependencies_data(podfile),
                      'EXTERNAL SOURCES' => generate_external_sources_data(podfile),
                      'CHECKOUT OPTIONS' => checkout_options,
                      'SPEC CHECKSUMS'   => generate_checksums(specs),
                      'PODFILE CHECKSUM' => podfile.checksum,
                      'EXTERNAL PODSPECS' => podspecs,
                      'COCOAPODS'        => CORE_VERSION,
                      'COCOAPODS DEPLOY' => '0.0.11' # - Get from cocoapods version
                    }
                    Lockfile.new(hash)
                end
            end
        end

        def write_lockfiles
         apply_lockfile_patch

         # How do we get URL for podspec on download that we can put here ?
         external_source_pods = podfile.dependencies.select(&:external_source).map(&:root_name).uniq
         checkout_options = sandbox.checkout_sources.select { |root_name, _| external_source_pods.include? root_name }
         @lockfile = Lockfile.generate(podfile, analysis_result.specifications, checkout_options, sandbox.external_podspecs)

         UI.message "- Writing Lockfile in #{UI.path config.lockfile_path}" do
           @lockfile.write_to_disk(config.lockfile_path)
         end

         UI.message "- Writing Manifest in #{UI.path sandbox.manifest_path}" do
           sandbox.manifest_path.open('w') do |f|
             f.write config.lockfile_path.read
           end
         end
       end
    end
end
