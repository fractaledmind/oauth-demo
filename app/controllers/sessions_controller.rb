class SessionsController < ApplicationController
  # GET /sessions/new
  def new
    @session = Session.new
  end
end
