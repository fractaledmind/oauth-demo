class UsersController < ApplicationController
  # GET /users/new
  def new
    @user = User.new
    render layout: "authentication"
  end
end
