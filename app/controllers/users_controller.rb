class UsersController < ApplicationController
  # GET /users/new
  def new
    @user = User.new
  end
end
