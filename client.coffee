exports.render = !->
	filterO = Obs.create {}
	Dom.style
		background: '#eee'
		minHeight: '100%'

	Obs.observe !->
		text = 'Latest commits'
		if (repo = filterO.get('repository'))
			text += ' on '+repo
		if (user = filterO.get('user'))
			text += ' by '+user
		Dom.h1 text
	Dom.div !->
		reset = Obs.create 0
		Dom.style
			padding: '0 0 50px 0'

		# Loglist setup
		lastV = Obs.create()
		Obs.observe !->
			lastV.set -(Db.shared.get('commitMaxId')||0)
		firstV = Obs.create()
		initFirst = !->
			firstV.set -Math.max(1, (Db.shared.peek('commitMaxId')||0)-50)
			reset.incr()
		initFirst()

		count = Obs.create 0
		Obs.observe !->
			reset.get()
			Loglist.render lastV, firstV, (num) !->
				num = -num
				commit = Db.shared.ref 'commits', num
				return if !commit.peek()?
				count.incr()
				Obs.onClean !->
					count.incr -1

				# Repository filter
				return if (repo = filterO.get('repository'))? and commit.get('repositoryName') isnt repo
				# User filter
				return if (user = filterO.get('user'))? and commit.get('byUsername') isnt user

				Dom.div !->
					Dom.style
						Box: 'horizontal'
						background: '#fff'
						boxShadow: '0 2px 4px rgba(0,0,0,0.1)'
						margin: '0 0 10px 0'
						padding: '0 10px 0 0'
					Dom.div !->
						avatarSize = 120
						avatar = commit.get 'avatar'
						if avatar
							if avatar.indexOf('?') isnt -1
								avatar += "&s="+avatarSize
							else
								avatar += "?s="+avatarSize
						Dom.style
							background: 'url("'+avatar+'")'
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
								Dom.div !->
									Dom.style
										display: 'inline-block'
										margin: '-5px'
										padding: '5px'
									Dom.text commit.get('repositoryName')
									Dom.onTap !->
										filterO.set 'repository', commit.get('repositoryName')
							Dom.div !->
								Dom.style
									fontSize: '12px'
									margin: '-5px'
									padding: '9px 5px'
								parsedDate = Date.parse(commit.get('date'))
								Time.deltaText parsedDate/1000
								Dom.onTap !->
									Modal.show !->
										Dom.div !->
											Dom.userText '**Committed:** '
											Dom.br()
											Dom.text new Date(parsedDate).toUTCString()
											Dom.br()
											Dom.userText '**Hash:** '
											Dom.br()
											Dom.text commit.get('hash')
						Dom.div !->
							Dom.style
								Box: 'horizontal'
								margin: '5px 0 0 0'
								fontSize: '15px'
							Dom.div !->
								Dom.div !->
									Dom.style
										margin: '-5px -5px 0 -5px'
										padding: '5px'
									Dom.userText '**'+commit.get('byUsername')+':**'
									Dom.onTap !->
										filterO.set 'user', commit.get('byUsername')
							Dom.div !->
								Dom.style
									marginLeft: '5px'
									paddingBottom: '7px'
									Flex: true
								Dom.userText commit.get('message')

		Obs.observe !->
			return if firstV.get() is -1
			Dom.div !->
				Dom.style
					Box: 'center'
					padding: '20px 0 10px 0'
				Ui.spinner 25
		singleLoadMore = ->
			if Page.near('bottom') < 600 and firstV.peek() isnt -1
				firstV.set Math.min(-1, firstV.peek()+5)
				true
		completeLoadMore = !->
			result = true
			while result
				result = singleLoadMore()
		Page.onScroll singleLoadMore

		Obs.observe !->
			completeLoadMore()
			filterO.get()

		Obs.observe !->
			if count.get() is 0
				Ui.emptyText 'No commits yet, program something!'

		Obs.observe !->
			footer = []
			if (repo = filterO.get('repository'))?
				footer.push
					label: !->
						Dom.text 'Clear repository filter:'
						Dom.div !->
							Dom.style textTransform: 'none'
							Dom.text repo
					action: !->
						initFirst()
						filterO.remove 'repository'
						Page.scroll 0
			if (user = filterO.get('user'))?
				footer.push
					label: !->
						Dom.text 'Clear user filter:'
						Dom.div !->
							Dom.style textTransform: 'none'
							Dom.text user
					action: !->
						initFirst()
						filterO.remove 'user'
						Page.scroll 0
			if footer.length > 0
				Page.setFooter footer

exports.renderSettings = !->
	if !Db.shared
		Dom.text 'After installing the plugin you can see the webhook url on the settings page.'
		return

	Dom.div !->
		Dom.style _userSelect: 'text'
		Dom.userText '**Webhook url**: '+App.inboundUrl()
	Dom.div !->
		Dom.style
			fontSize: '14px'
			marginTop: '2px'
		Dom.text 'Add this url as webhook in BitBucket or GitHub'