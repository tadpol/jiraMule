require 'uri'
require 'net/http'
require 'json'

module JiraMule
  module Http

    def json_opts
      return @json_opts unless not defined?(@json_opts) or @json_opts.nil?
      @json_opts = {
        :allow_nan => true,
        :symbolize_names => true,
        :create_additions => false
      }
    end

    def curldebug(request)
      if $cfg['tool.curldebug'] then
        a = []
        a << %{curl -s }
        if request.key?('Authorization') then
          a << %{-H 'Authorization: #{request['Authorization']}'}
        end
        a << %{-H 'User-Agent: #{request['User-Agent']}'}
        a << %{-H 'Content-Type: #{request.content_type}'}
        a << %{-X #{request.method}}
        a << %{'#{request.uri.to_s}'}
        a << %{-d '#{request.body}'} unless request.body.nil?
        puts a.join(' ')
      end
    end

    def http
      uri = URI('https://' + $cfg['net.host'])
      if not defined?(@http) or @http.nil? then
        @http = Net::HTTP.new(uri.host, uri.port)
        @http.use_ssl = true
        @http.start
      end
      @http
    end
    def http_reset
      @http = nil
    end

    def set_def_headers(request)
      request.content_type = 'application/json'
      request['Authorization'] = 'token ' + token #FIXME broken
      request['User-Agent'] = "JiraMule/#{JiraMule::VERSION}"
      request
    end

    def isJSON(data)
      begin
        return true, JSON.parse(data, json_opts)
      rescue
        return false, data
      end
    end

    def showHttpError(request, response)
      if $cfg['tool.debug'] then
        puts "Sent #{request.method} #{request.uri.to_s}"
        request.each_capitalized{|k,v| puts "> #{k}: #{v}"}
        if request.body.nil? then
        else
          puts " > #{request.body[0..156]}"
        end
        puts "Got #{response.code} #{response.message}"
        response.each_capitalized{|k,v| puts "< #{k}: #{v}"}
      end
      isj, jsn = isJSON(response.body)
      resp = "Request Failed: #{response.code}: "
      if isj then
        if $cfg['tool.fullerror'] then
          resp << JSON.pretty_generate(jsn)
        else
          resp << "[#{jsn[:statusCode]}] " if jsn.has_key? :statusCode
          resp << jsn[:message] if jsn.has_key? :message
        end
      else
        resp << jsn
      end
      say_error resp
    end

    def workit(request, &block)
      curldebug(request)
      if block_given? then
        return yield request, http()
      else
        response = http().request(request)
        case response
        when Net::HTTPSuccess
          return {} if response.body.nil?
          begin
            return JSON.parse(response.body, json_opts)
          rescue
            return response.body
          end
        else
          showHttpError(request, response)
          raise response
        end
      end
    end

    def get(path='', &block)
      uri = endPoint(path)
      workit(set_def_headers(Net::HTTP::Get.new(uri)), &block)
    end

    def post(path='', body={}, &block)
      uri = endPoint(path)
      req = Net::HTTP::Post.new(uri)
      set_def_headers(req)
      req.body = JSON.generate(body)
      workit(req, &block)
    end

    def postf(path='', form={}, &block)
      uri = endPoint(path)
      req = Net::HTTP::Post.new(uri)
      set_def_headers(req)
      req.content_type = 'application/x-www-form-urlencoded; charset=utf-8'
      req.form_data = form
      workit(req, &block)
    end

    def put(path='', body={}, &block)
      uri = endPoint(path)
      req = Net::HTTP::Put.new(uri)
      set_def_headers(req)
      req.body = JSON.generate(body)
      workit(req, &block)
    end

    def delete(path='', &block)
      uri = endPoint(path)
      workit(set_def_headers(Net::HTTP::Delete.new(uri)), &block)
    end

  end
end
#  vim: set ai et sw=2 ts=2 :
