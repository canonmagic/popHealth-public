
module Api
  class ValueSetsController < ApplicationController
    respond_to :json
    #before_action :authenticate_user!
    skip_authorization_check

    api :GET, '/value_sets/:oid?search=:search'
    param :oid, String, :desc => "Value set OID", :required => true
    param :search, String, :desc => "Value set term search string", :required => false
    def show
      #Valuesets are searched by Id,s Rather than dispaly names
      begin
        s=params[:search]
        rx=Regexp.new("${s}")
        # assume user typed in a start of a word so sort
        sortfun=lambda { |x| rx=~x['display_name'] }
        if /^[0-9]+[.]/ =~ params[:oid]
          concepts_group = []
          uniq_concpets =[]
          value_set = ValueSet.where({oid: params[:oid]}).first
          
          if (params[:oid] == '2.16.840.1.114222.4.11.3591')
          #Removing Duplicates injected by Valueset bundle 2019
          concepts_group = value_set.concepts.all({code: /#{s}/i }).sort_by{|payers| payers[:code].to_i}
          uniq_concpets = concepts_group.index_by{|r| r[:code]}.values
          else
          #Removing Duplicates injected by Valueset bundle 2019
          concepts_group = value_set.concepts.all({display_name: /#{s}/i }).sort_by!(&sortfun)
          uniq_concpets = concepts_group.index_by{|r| r[:code]}.values
          end

          render json: uniq_concpets
        else
          value_set = ValueSet.where({display_name: /#{s}/i}).all.to_a
          value_set.sort_by!(&sortfun)
          render json: value_set
        end
      rescue Exception => e
        puts e.message
        puts e.backtrace.inspect
        Delayed::Worker.logger.info(e.message)
        Delayed::Worker.logger.info(e.backtrace.inspect)
      end
    end
  end
end