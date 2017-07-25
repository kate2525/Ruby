require 'open-uri'
require 'nokogiri'
require 'json'
require 'openssl'
require 'net/https'
require 'net/http'
require 'rubygems'
require 'uri'
require 'csv'

#старт скрипта
def start (url)

	puts "start()"

	nextPageUrlFull = url
	
	i = 0 #Просто для вывода в консоли, что-бы визуально знать номер страницы

	#делаем обход по всем страницам - пейджинг
	loop do 

		puts "Page #{i}"
		i = i + 1
	  
		html = open(nextPageUrlFull)
		doc = Nokogiri::HTML(html)

		#вызываем функцию parseProductList и подаем в нее переменную doc
		#в этой функции будет все парсица и сохранятся в CSV
		parseProductList(doc)
		
		#ищем ссылку на следующую страницу
		nextPageElement = doc.at_css('li.pagination_next a[href]')

		#если есть тег содержащий ссылку на следующую страницу
		if !nextPageElement.nil?
		#if i == 0
			nextPageUrl = nextPageElement['href']
			puts "nextPageUrl = #{nextPageUrl}"

			#так как ссылка относительная, делам из нее абсолютную ссылку
			nextPageUrlFull = URI.join(url,nextPageUrl).to_s
			puts "nextPageUrlFull = #{nextPageUrlFull}"
		else 
			break #ссылок больше нет, значит все продукты обработаны
		end	

	end 

	puts "end start()"

end 


#делаем парсинг страницы где список продуктов
def parseProductList (doc)

	puts "parseProductList()"

	#получаем элементы каждого продукта
	productlists = []
	productlist = doc.css('.productlist').map do |productlist| 

		#получаем ссылки на продукты
		urlList = []
		urlList = productlist.css('div.view a.lnk_view').map { |link| link['href'] }   
		
		for oneUrl in urlList do
	  		parseProductPage(oneUrl)
		end

	end

	puts "end parseProductList"

end

#Делаем парсинг конкретно страницы по заданной ссылке и сохраняем все в файл
def parseProductPage (url)

	#url - ссылка на конкретную страницу продукта

	puts "parseProductPage() #{url}"

	html = open(url)
	doc = Nokogiri::HTML(html) # в doc - html конкретной страницы продукта

	titleElement = doc.at_css('.product-name h1')
	titleElement.children.each { |c| c.remove if c.name == 'span' }
	title = titleElement.text.strip 
	puts "Title== #{title}"

	image = doc.at_css('#image-block img[src]')['src']
	puts "IMAGE== #{image}"
	 
	 
	typesElement = doc.at_css('div.attribute_list')
	 
	if !typesElement.nil?
		#есть разные виды товаров

		typeslist = doc.css('ul.attribute_labels_lists').map do |typeslist| 

			gramsElement = typeslist.css('span.attribute_name')	
			grams = gramsElement.text.strip 
			puts "GRAMS== #{grams}"

			priceElement = typeslist.css('span.attribute_price')	
			price = priceElement.text.strip 
			puts "PRICE== #{price}"

			saveToCSV(title + ' - ' +  grams, image, price)
		end

	 else
			#разновидностей товаров нет
			priceElement = doc.at_css('span#price_display')	
			price = priceElement.text.strip 
			puts "PRICE== #{price}"
			saveToCSV(title, image, price)
	 end

	puts "end parseProductPage()"
end

#делаем запись в CSV файле
def saveToCSV (title, image, price)

	puts "saveToCSV()"

	puts "!!! TITLE = #{title}"
	puts "!!! IMAGE = #{image}"
	puts "!!! PRICE = #{price}"

	CSV.open(ARGV[1] + ".csv", "ab") do |csv|
		csv << [title, image, price]
		puts "CSV=== #{csv}" 
	end

end

#'https://www.petsonic.com/snacks-huesos-para-perros/'
#вызов метода start
start ARGV[0]


