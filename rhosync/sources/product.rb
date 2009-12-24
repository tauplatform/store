require 'json'
require 'net/http'
require 'open-uri'

class Product < SourceAdapter
  def initialize(source,credential)
    super(source,credential)
  end
 
  def login
  end
 
  # backend for this source adapter doesnt implement condtions but limit and offset
  def query(conditions=nil,limit=nil,offset=nil)

    url="http://rhostore.heroku.com/products.json"
    if limit & offset
      url += "?limit=#{limit}&offset=#{offset}"
    end
    
    parsed=nil
    open(url) do |f|
      parsed=JSON.parse(f.read)
    end
    
    puts parsed.inspect.to_s
    @result={}
    
    parsed.each { |item|@result[item["product"]["id"].to_s]=item["product"] } if parsed
    puts @result.inspect.to_s
    
    @result
  end
 
  def sync
    # TODO: write code here that converts the data you got back from query into an @result object
    # where @result is an array of hashes,  each array item representing an object
    super # this creates object value triples from an @result variable that contains an array of hashes
  end
 
  def create(name_value_list)
    attrvals={}
    name_value_list.each { |key,value| attrvals["product["+key.to_s+"]"]=value.to_s } # convert name-value list to hash
    res = Net::HTTP.post_form(URI.parse("http://rhostore.heroku.com/products"),attrvals)
    
    # after create we are redirected to the new record. We need to get the id of that record and return it as part of create
    # so rhosync can establish connection from its temporary object on the client to this newly created object on the server
    case res
      when Net::HTTPRedirection 
        parsed = {}
        open(res['location']+".json") do |f|
          parsed=JSON.parse(f.read)
        end
        return parsed["product"]["id"] rescue nil
    end
  end
 
  def update(name_value_list) 
    obj_id = name_value_list['id']
    name_value_list.delete('id')   

    uri = URI.parse('http://rhostore.heroku.com')
    Net::HTTP.start(uri.host) do |http|
      request = Net::HTTP::Put.new(uri.path + "/products/#{obj_id}.xml", {'Content-type' => 'application/xml'})
      request.body = xml_template(name_value_list)
      response = http.request(request)
    end
  end
 
  def delete(name_value_list)   
    http=Net::HTTP.new('rhostore.heroku.com',80)
    path="/products/#{name_value_list['id']}"
    resp=http.delete(path)
  end
 
  def logoff
    #TODO: write some code here if applicable
    # no need to do a raise here
  end
  
  protected
  # API is expecting us to send XML content
  def xml_template(params)
    xml_str = "<product>"
    params.each do |key,value|
      xml_str += "<#{key}>#{value}</#{key}>"
     end
     xml_str += "</product>"
     xml_str
   end
end