require "rubygems"
require "bundler/setup"
require "highrise"
require "mechanize"

HIGHRISE_URL = "https://cozily.highrisehq.com"
HIGHRISE_KEY = "ee857e8b0b739daaf414db1162a23524"

Highrise::Base.site = HIGHRISE_URL
Highrise::Base.user = HIGHRISE_KEY
Highrise::Base.format = :xml

agent = Mechanize.new

(1..999).each do |id|
  url = "http://urbansherpany.com/OwnerHome/#{id}"
  page = agent.get(url)
  data = {}

  puts "### #{url}"
  data[:name] = page.search("div#landlord_header").inner_html.strip
  if data[:name].blank?
    puts "*** Looks blank, skipping!"
    next
  end

  data[:source_url] = url

  data[:num_buildings] = page.search("table#all_build_info > tr:nth-child(1) > td:nth-child(2)").inner_text.strip
  data[:num_apartments] = page.search("table#all_build_info > tr:nth-child(2) > td:nth-child(2)").inner_text.strip

  data[:address] = page.search("div#left_column > table.info > tr > td:contains('ADDRESS') + td").inner_text.strip
  data[:primary_phone] = page.search("div#left_column > table.info > tr > td:contains('PHONE NUMBER') + td").inner_text.strip
  data[:secondary_phone] = page.search("div#left_column > table.info > tr > td:contains('SECONDARY PHONE') + td").inner_text.strip
  data[:fax] = page.search("div#left_column > table.info > tr > td:contains('FAX') + td").inner_text.strip
  data[:website] = page.search("div#left_column > table.info > tr > td:contains('WEBSITE') + td").inner_text.strip
  data[:updated_at] = page.search("div#left_column > table.info > tr > td:contains('MOST RECENT UPDATE') + td").inner_text.strip

  data[:description] = page.search("div#left_column > h1:contains('Description') + div").inner_text.strip

  params = {}.tap do |param|
    param[:name] = data[:name]
    param[:background] = data[:description] unless data[:description].blank?
    param[:contact_data] = {}.tap do |contact|
      contact[:phone_numbers] = [].tap do |phone_number|
        phone_number << {:number => data[:primary_phone], :location => "Work"} unless data[:primary_phone].blank?
        phone_number << {:number => data[:secondary_phone], :location => "Work"} unless data[:secondary_phone].blank?
        phone_number << {:number => data[:fax], :location => "Fax"} unless data[:fax].blank?
      end

      contact[:web_addresses] = [].tap do |web_address|
        web_address << {:url => data[:website], :location => "Work"} unless data[:website].blank?
      end

      contact[:addresses] = [].tap do |address|
        address << {:street => data[:address], :city => "New York", :state => "NY", :location => "Work"} unless data[:address].blank?
      end
    end

    param[:subject_datas] = [].tap do |subject_data|
      subject_data << {:value => data[:num_buildings], :subject_field_id => 502806} unless data[:num_buildings].blank?
      subject_data << {:value => data[:num_apartments], :subject_field_id => 502807} unless data[:num_apartments].blank?
      subject_data << {:value => data[:source_url], :subject_field_id => 502824}
      subject_data << {:value => data[:updated_at], :subject_field_id => 502825} unless data[:updated_at].blank?
    end
  end

  puts params.inspect
  Highrise::Company.create(params)
end

