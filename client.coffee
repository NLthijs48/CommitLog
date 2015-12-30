Db = require 'db'
Dom = require 'dom'
Modal = require 'modal'
Obs = require 'obs'
Plugin = require 'plugin'
Page = require 'page'
Server = require 'server'
Ui = require 'ui'
Time = require 'time'

exports.render = !->
	Dom.style
		background: '#eee'

	Dom.h1 'Latest commits'
	Dom.div !->
		Dom.style
			margin: '10px 0 50px 0'
		count = 0
		Db.shared.iterate 'commits', (commit) !->
			count++
			Dom.div !->
				Dom.style
					Box: 'horizontal'
					background: '#fff'
					boxShadow: '0 2px 4px rgba(0,0,0,0.1)'
					margin: '0 0 10px 0'
					padding: '0 10px 0 0'
				Dom.div !->
					Dom.style
						background: 'url("'+commit.get('avatar')+'")'
						backgroundSize: 'contain'
						backgroundRepeat: 'no-repeat'
						backgroundPosition: 'center center'
						width: '60px'
						height: '60px'
				Dom.div !->
					Dom.style
						Flex: 1
						margin: '0 0 0 10px'
					Dom.div !->
						Dom.style
							Box: 'horizontal center center'
							borderBottom: '2px solid'
							paddingBottom: '2px'
							marginTop: '5px'
						Dom.div !->
							Dom.style
								Flex: true
								fontSize: '115%'
								#color: '#00AA00'
								fontWeight: 'bold'
							Dom.text commit.get('repositoryName')
						Dom.div !->
							Dom.style
								fontSize: '12px'
								marginTop: '4px'
							parsedDate = Date.parse(commit.get('date'))
							Time.deltaText parsedDate/1000
							log 'parsedDate', parsedDate
							Dom.onTap !->
								Modal.show !->
									Dom.style _userSelect: 'text'
									Dom.text 'Committed at '+(new Date(parsedDate).toUTCString())
									Dom.br()
									Dom.text 'Hash: '+commit.get('hash')
					Dom.div !->
						Dom.style
							Box: 'horizontal'
							marginTop: '5px'
							fontSize: '15px'
						Dom.div !->
							Dom.userText '**'+commit.get('byUsername')+':**'
						Dom.div !->
							Dom.style
								marginLeft: '5px'
								paddingBottom: '7px'
							Dom.userText commit.get('message')
		, (commit) ->
			-(Date.parse(commit.get('date')))

		if count is 0
			Ui.emptyText 'No commits yet, program something!'

exports.renderSettings = !->
	if !Db.shared
		Dom.text 'After installing the plugin you can see the webhook url on the settings page.'
		return

	Dom.div !->
		Dom.style _userSelect: 'text'
		Dom.userText '**Webhook url**: '+Plugin.inboundUrl()
	Dom.div !->
		Dom.style
			fontSize: '14px'
			marginTop: '2px'
		Dom.text 'Add this url as webhook in BitBucket'