require "unsplitter/version"
require 'active_record'
require 'activerecord-jdbc-adapter'
require 'logger'
require 'hashdiff'
require 'db_unsplitter'
require 'ex_task'


module Unsplitter
  class << self
    attr_accessor :logger
  end
end
