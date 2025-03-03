module Api
  module Admin
    class ProvidersController < ApplicationController
      resource_description do
        resource_id 'Admin::Providers'
        short 'Providers Admin'
        formats ['json']
        description "This resource allows for administrative tasks to be performed on providers via the API."
      end
      include LogsHelper
      protect_from_forgery except: [:create, :destroy]

      before_action :authenticate_user!
      before_action :validate_authorization!

      api :GET, "/admin/providers/count", "Get count of providers in the database"
      formats ['json']
      example '{"provider_count":2}'
      def count
        json = {}
        json['provider_count'] = Provider.count

        render :json => json
      end

      api :POST, "/admin/providers", "Upload an opml file of providers."
      param :file, nil, :desc => 'The ompl file of providers to upload.', :required => true
      def create
        log_call LogAction::IMPORT, "API Admin Providers Controller - Import an OPML file with providers"

        file = params[:file]
        FileUtils.mkdir_p(File.join(Dir.pwd, "tmp/import"))
        file_location = File.join(Dir.pwd, "tmp/import")
        file_name = "provider_upload" + Time.now.to_i.to_s + rand(1000).to_s

        temp_file = File.new(file_location + "/" + file_name, "w")

        File.open(temp_file.path, "wb") { |f| f.write(file.read) }

        provider_tree = ProviderTreeImporter.new(File.open(temp_file))
        provider_tree.load_providers(provider_tree.sub_providers)

        render status: 200, text: 'Provider opml has been uploaded.'
      end

      api :DELETE, "/admin/providers", "Delete all providers in the database."
      def destroy
        log_call LogAction::DELETE, "API Admin Providers Controller - Remove all providers"

        Provider.delete_all

        render status: 200, text: 'Provider records successfully removed from database.'
      end

      private 

      def validate_authorization!
        authorize! :admin, :users
      end
    end
  end
end