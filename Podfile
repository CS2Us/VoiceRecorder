platform :ios, '10.0'

target 'DSPKit' do
	use_frameworks!
	
	pod 'mobile-ffmpeg-full', '~> 3.1'
end

target 'RecordKit' do
	use_frameworks!
	
end

target 'VoiceRecorderDemo' do
	use_frameworks!
	
#	pod 'PRTween', '~> 0.1'

end

#bitcode enable
post_install do |installer|
	installer.pods_project.targets.each do |target|
		target.build_configurations.each do |config|
			config.build_settings['ENABLE_BITCODE'] = 'YES'
			
			if config.name == 'Release'
				config.build_settings['BITCODE_GENERATION_MODE'] = 'bitcode'
				else
				config.build_settings['BITCODE_GENERATION_MODE'] = 'marker'
			end
			
			cflags = config.build_settings['OTHER_CFLAGS'] || ['$(inherited)']
			
			if config.name == 'Release'
				cflags << '-fembed-bitcode'
				else
				cflags << '-fembed-bitcode-marker'
			end
			
			config.build_settings['OTHER_CFLAGS'] = cflags
		end
	end
end
