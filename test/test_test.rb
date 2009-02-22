require 'yaml'
require File.dirname(__FILE__) + '/helper'

describe 'Sinatra::Test' do
  def request
    YAML.load(body)
  end

  def request_body
    request['test.body']
  end

  def request_params
    YAML.load(request['test.params'])
  end

  before do
    mock_app {
      %w[get head post put delete].each { |verb|
        send(verb, '/') do
          env.update('test.body'   => request.body.read)
          env.update('test.params' => params.to_yaml)
          env.to_yaml
        end
      }

      get '/redirect_me' do
        redirect '/there'
      end

      get '/there' do
        "you've been redirected"
      end
    }
  end

  it 'allows GET/POST/PUT/DELETE' do
    get '/'
    assert_equal('GET', request['REQUEST_METHOD'])

    post '/'
    assert_equal('POST', request['REQUEST_METHOD'])

    put '/'
    assert_equal('PUT', request['REQUEST_METHOD'])

    delete '/'
    assert_equal('DELETE', request['REQUEST_METHOD'])
  end

  it 'allows to specify a body' do
    post '/', '42'
    assert_equal '42', request_body
  end

  it 'allows to specify params' do
    get '/', :foo => 'bar'
    assert_equal 'bar', request_params['foo']
  end

  it 'supports nested params' do
    get '/', :foo => { :x => 'y', :chunky => 'bacon' }
    assert_equal "y", request_params['foo']['x']
    assert_equal "bacon", request_params['foo']['chunky']
  end

  it 'provides easy access to response status and body' do
    get '/'
    assert_equal 200, status
    assert body =~ /^---/
  end

  it 'delegates methods to @response' do
    get '/'
    assert ok?
  end

  it 'follows redirect' do
    get '/redirect_me'
    follow!
    assert_equal "you've been redirected", body
  end

  it 'provides sugar for common HTTP headers' do
    get '/', :env => { :accept => 'text/plain' }
    assert_equal 'text/plain', request['HTTP_ACCEPT']

    get '/', :env => { :agent => 'TATFT' }
    assert_equal 'TATFT', request['HTTP_USER_AGENT']

    get '/', :env => { :host => '1.2.3.4' }
    assert_equal '1.2.3.4', request['HTTP_HOST']

    get '/', :env => { :session => 'foo' }
    assert_equal 'foo', request['HTTP_COOKIE']

    get '/', :env => { :cookies => 'foo' }
    assert_equal 'foo', request['HTTP_COOKIE']

    get '/', :env => { :content_type => 'text/plain' }
    assert_equal 'text/plain', request['CONTENT_TYPE']
  end

  def test_TestHarness
    session  = Sinatra::TestHarness.new(@app)
    response = session.get('/')
    assert_equal 200, response.status
  end
end
