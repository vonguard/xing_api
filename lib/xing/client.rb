module Xing
  class Client
    include Xing::ResponseHandler
    attr_accessor :consumer_key, :consumer_secret, :oauth_token, :oauth_token_secret

    class << self
      attr_accessor :default_options
    end

    def initialize(options={})
      options = (self.class.default_options ||= {}).merge(options)
      @consumer_key = options[:consumer_key]
      @consumer_secret = options[:consumer_secret]
      @oauth_token = options[:oauth_token]
      @oauth_token_secret = options[:oauth_token_secret]
    end

    def self.configure(&block)
      instance = self.new
      yield instance
      self.default_options = instance.send(:to_hash)
    end

    def request(http_verb, url, options={})
      full_url = url + hash_to_params(options)
      handle(access_token.request(http_verb, full_url))
    end

    def get_authorize_url
      request_token.authorize_url
    end

    def authorize(verifier)
      access_token = request_token.get_access_token(:oauth_verifier => verifier)
      self.oauth_token = access_token.token
      self.oauth_token_secret = access_token.secret
      self.class.default_options[:consumer_key] = consumer_key
      self.class.default_options[:consumer_secret] = consumer_secret
      self.class.default_options[:oauth_token] = oauth_token
      self.class.default_options[:oauth_token_secret] = oauth_token_secret
      true
    end

    def get_request_token(oauth_callback='oob')
      request_token(oauth_callback)
    end

    def get_access_token(verifier, token, secret)
      request_token = OAuth::RequestToken.new(consumer, token, secret)
      access_token = request_token.get_access_token(:oauth_verifier => verifier)
      self.oauth_token = access_token.token
      self.oauth_token_secret = access_token.secret
      access_token
    end

    private

    def to_hash
      {
        :consumer_key => consumer_key,
        :consumer_secret => consumer_secret,
        :oauth_token => oauth_token,
        :oauth_token_secret => oauth_token_secret
      }
    end

    def request_token(oauth_callback)
      @request_token ||= consumer.get_request_token(:oauth_callback => oauth_callback)
    end

    def consumer
      OAuth::Consumer.new(consumer_key, consumer_secret, default_options)
    end

    def access_token
      OAuth::AccessToken.new(consumer, oauth_token, oauth_token_secret)
    end

    def default_options
      {
        :site               => 'https://api.xing.com',
        :request_token_path => '/v1/request_token',
        :authorize_path     => '/v1/authorize',
        :access_token_path  => '/v1/access_token',
        :signature_method   => 'PLAINTEXT',
        :oauth_version      => '1.0',
        :scheme             => 'query_string'
      }
    end

    def hash_to_params(hash)
      return '' if hash.empty?
      '?' + hash.map {|k,v| "#{k}=#{CGI.escape(v.to_s)}"}.join('&')
    end

  end
end
