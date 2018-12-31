#!/usr/bin/env ruby
require 'date'
require 'optparse'
require 'rubygems'
require 'resolv'
require 'socket'
require 'timeout'
require 'rex'
require 'thread'
require 'net/http'
require 'uri'
require 'selenium-webdriver'
require 'time'
require 'pry'
@write_mutex = Mutex.new
STDOUT.sync = true

def CheckFile(csv,realcsv=nil)
    csv = csv.strip
    ip = csv.split(',')[9]
    address = ip.strip.chomp

    if File.readlines("Database.csv").grep(/#{address}/).size > 0
        puts 'Skipping dups'
    else

    if csv.include? "F5 BIG-IP load balancer"
        File.open('bannergrabber.csv', 'a') do |f|
	         f.write "#{csv.strip},F5 BIG-IP load balancer\n"
             @write_mutex.synchronize{puts "Wrote to file, F5 BIG-IP load balancer------------------------------"}
        end
    else
        realcsv = address
        return realcsv
    end
    end
end

def InitialRequestBOTH(csv, realcsv)
    address = realcsv.strip
    capabilities = Selenium::WebDriver::Remote::Capabilities.firefox(accept_insecure_certs: true, acceptSslCerts: true, handlesAlerts: true, unexpectedAlertBehaviour: true)
    driver = Selenium::WebDriver.for :firefox, :desired_capabilities => capabilities
    driver.manage.timeouts.page_load = 20
	 begin
		Timeout::timeout(21) do
			#driver.manage.window.resize_to(1000, 1000)# resize the window and take a screenshot
			#driver.save_screenshot "thread.png"
			url = "#{address.chomp.strip}"
         protocol = url.split("\/").first
         domain = url.split("\/").last
         url = protocol+"//admin:admin@"+domain+"/"
			driver.navigate.to(url)
         sleep(3)

			if driver.title.empty?
				File.open('bannergrabber.csv', 'a') do |f|
					 f.write "#{csv.strip},NO TITLE\n"
                     @write_mutex.synchronize{puts "Wrote to file, No Title------------------------------"}
			    end
                driver.quit
			else

            if driver.title.include? "401 Unauthorized" and driver.current_url.include? "/view/view.shtml?id="
				File.open('bannergrabber.csv', 'a') do |f|
					 f.write "#{csv.strip},Axis Camera\n"
                     @write_mutex.synchronize{puts "Wrote to file, Axis Camera------------------------------"}
			    end
                driver.quit
            else

            time1 = Time.new
			@write_mutex.synchronize{puts "#{url},#{driver.title}\t#{time1.inspect}"}
				File.open('bannergrabber.csv', 'a') do |f|
					 f.write "#{csv.strip},#{driver.title}\n"
                     @write_mutex.synchronize{puts "Wrote to file, now to call driver.quit------------------------------"}
                     driver.quit
			end
			end
         end
		end
        rescue Selenium::WebDriver::Error::UnexpectedAlertOpenError
		File.open('bannergrabber.csv', 'a') do |f|
			 f.write "#{csv.strip},Error::UnexpectedAlertOpenError\n"
             @write_mutex.synchronize{puts "Error::UnexpectedAlertOpenError-PRINTED TO FILE------------------------------"}
	    end
        driver.quit

        rescue Selenium::WebDriver::Error::UnhandledAlertError
		File.open('bannergrabber.csv', 'a') do |f|
			 f.write "#{csv.strip},Error::UnhandledAlertError\n"
             @write_mutex.synchronize{puts "Error::UnhandledAlertError-PRINTED TO FILE------------------------------"}
	    end
        driver.quit

        rescue Net::ReadTimeout
        @write_mutex.synchronize{puts "Net::ReadTimeout------------------------------"}
        driver.close

        rescue Timeout::Error
		File.open('bannergrabber.csv', 'a') do |f|
			 f.write "#{csv.strip},Timeout::Error\n"
             @write_mutex.synchronize{puts "Timeout::Error-PRINTED TO FILE------------------------------"}
	    end
        driver.quit

        rescue Selenium::WebDriver::Error::TimeOutError
		File.open('bannergrabber.csv', 'a') do |f|
			 f.write "#{csv.strip},Error::TimeOutError\n"
             @write_mutex.synchronize{puts "Error::TimeOutError-PRINTED TO FILE------------------------------"}
	    end
        driver.quit

        rescue Selenium::WebDriver::Error::NoSuchDriverError
        @write_mutex.synchronize{puts "Selenium::WebDriver::Error::NoSuchDriverError------------------------------"}
        driver.quit

        rescue Errno::ECONNREFUSED
		File.open('bannergrabber.csv', 'a') do |f|
			 f.write "#{csv.strip},Errno::ECONNREFUSED\n"
             @write_mutex.synchronize{puts "Errno::ECONNREFUSED-PRINTED TO FILE------------------------------"}
	    end
        driver.quit

        rescue EOFError
        @write_mutex.synchronize{puts "EOFError------------------------------"}
        driver.quit

		rescue Exception => ex
        @write_mutex.synchronize{puts "Exception------------------------------"}
		$stderr.puts File.expand_path $0
		$stderr.puts ex.class
		$stderr.puts ex
        driver.quit
	end
end

options={}
optparse = OptionParser.new do |opts|
	opts.banner = "Usage: TitleGrabber.rb [options] ip/file"
	options[:list] = false
	opts.on( '-l', '--list', 'Take input from a text file list, one IP per line') do
		$stderr.print "Reading input file..."
		list = File.readlines(ARGV[0])
		$stderr.print "...file read.\nCreating Mutex and threads..."
		THREAD_COUNT = 10
		mutex = Mutex.new
		$stderr.print "...mutex created. Start! #{File.expand_path $0}\n"
		THREAD_COUNT.times.map{
			Thread.new(list) do |ips|
				while ip = mutex.synchronize {ips.pop}
					initValue = CheckFile(ip.gsub(/\n/, ""))
                    if initValue
					    InitialRequestBOTH(ip.gsub(/\n/, ""), initValue)
                    end
				end
			end
		}.each(&:join)
	end
	options[:single] = false
	opts.on( '-s', '--single', 'Take input of a single IP passed through the command line') do
		$stderr.flush
		initValue = CheckFile(ARGV[0])
        if initValue
		    InitialRequestBOTH(ARGV[0], initValue)
        end
		exit
	end
end.parse!
