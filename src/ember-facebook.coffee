## ==========================================================================
## Project:    Ember Facebook
## Copyright:  ©2012 Luan Santos
## License:    Licensed under MIT license (see LICENSE)
## ==========================================================================

## ------------------------------------------------------------
## Facebook Mixin..
## ------------------------------------------------------------
Ember.Facebook = Ember.Mixin.create
	FBUser: undefined
	appId: undefined
	facebookParams: Ember.Object.create()
	fetchPicture: true

	init: ->
		@_super()
		window.FBApp = this

	facebookConfigChanged: (->
		# Em.Logger.info '--> in facebookConfigChanged..'
		@removeObserver('appId')
		window.fbAsyncInit = => @fbAsyncInit()

		$ ()->
			js = document.createElement 'script'

			$(js).attr {
				id: 'facebook-jssdk'
				# async: true
				src: '//connect.facebook.net/en_US/sdk.js'
			}

			$('body').prepend js
			$('body').prepend $('<div>').attr('id', 'fb-root')
	).observes('appId')

	fbAsyncInit: ->
		# Em.Logger.info '--> in fbAsyncInit..'
		facebookParams = @get('facebookParams')
		facebookParams = facebookParams.setProperties
			appId: @get 'appId' || facebookParams.get('appId') || undefined
			status: facebookParams.get('status') || true
			cookie: facebookParams.get('cookie') || true
			xfbml: facebookParams.get('xfbml') || true
			channelUrl: facebookParams.get('channelUrl') || undefined
			version: 'v2.1'

		# Em.Logger.info 'facebookParams', facebookParams

		FB.init facebookParams

		# @set 'FBloading', true
		FB.Event.subscribe 'auth.authResponseChange', (response) => @updateFBUser(response)
		FB.getLoginStatus (response) => @updateFBUser(response)

	updateFBUser: (response) ->
		# FB.Event.subscribe 'auth.authResponseChange', (response) => @updateFBUser(response)
		# Em.Logger.info '--> in updateFBUser..', response

		if response.status is 'connected'

			# to check for permissions..
			# FB.api '/me/permissions', (response)=>
			# 	if response and !response.error
			# 		Em.Logger.info 'permissions >>', response

			FB.api '/me', (user) =>
				FBUser = Ember.Object.create user
				FBUser.set 'accessToken', response.authResponse.accessToken
				FBUser.set 'expiresIn', response.authResponse.expiresIn

				if @get 'fetchPicture'
					FB.api '/me/picture?redirect=0&width=50&height=50&type=normal', (resp) =>
						FBUser.picture = resp.data.url
						@set('FBUser', FBUser)
						@checkEmail(FBUser)
				else
					@set('FBUser', FBUser)
					@checkEmail(FBUser)

		else
			@set 'User', false
			@set 'FBUser', false
			@set 'FBloading', false

	checkEmail: (FBUser)->
		if Ember.empty FBUser.email
			Em.Logger.info 'email does not exist!!'
			@set 'FBloading', false
		else
			@wpLogin(FBUser)

	wpLogin: (FBUser)->
		Em.Logger.info 'in FB wpCreateUser.....', FBUser

		data =
			action: 'users',
			fbId: FBUser.id
			firstName: FBUser.first_name
			lastName: FBUser.last_name
			email: FBUser.email

		Em.$.post(App.ajaxUrl, data).then (response)=>
			@set 'FBloading', false

			# User = Ember.Object.create()
			# App.User.set 'id', response.user.id
			# App.User.set 'fbId', response.user.fbId
			# App.User.set 'firstName', response.user.firstName
			# App.User.set 'lastName', response.user.lastName
			# App.User.set 'email', response.user.email
			# App.User.set 'profilePic', @FBUser.picture
			# @set 'User', User
			# @controllerFor('application').set 'user', 'test here..'

## ------------------------------------------------------------
## FacebookView
## ------------------------------------------------------------
Ember.FacebookView = Ember.View.extend
	classNameBindings: ['className']
	attributeBindings: []

	init: ->
		@_super()
		@setClassName()
		@attributeBindings.pushObjects(attr for attr of this when attr.match(/^data-/)?)

	setClassName: ->
		@set 'className', "fb-#{@type}"

	parse: ->
		FB.XFBML.parse @$().parent()[0].context if FB?

	didInsertElement: ->
		@parse()