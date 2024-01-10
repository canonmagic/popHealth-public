class MeasuresController < ApplicationController

    require 'will_paginate/mongoid'

    Model = CQM::Measure

    def index

        @measures = Model.all.paginate(page: params[:page], per_page: 5)

    end

    def edit

        @measure = Model.find(params[:id])

    end

    def update

        @measure = Model.find(params[:id])

        if @measure.update(measure_params)

            flash[:notice] = "Measure Updated Successfully"

            redirect_to edit_measure_path(@measure)

        else

            render :edit

        end

    end


    private

    def measure_params

        params.require(:cqm_measure).permit(:description)

    end

end
