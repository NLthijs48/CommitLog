Db = require 'db'
Http = require 'http'
Event = require 'event'

exports.onHttp = (request) !->
	if !request.data?
		log 'HTTP: no data'
		return

	parsed = JSON.parse request.data
	if !parsed?
		log 'HTTP: could not parse data'
		return

	if !parsed.push?.changes?
		log 'no changes listed in the data'
		return

	general = {}
	general.byName = parsed.actor?.display_name
	general.byUsername = parsed.actor?.username
	general.byUUID = parsed.actor?.uuid
	general.avatar = parsed.actor?.links?.avatar?.href
	general.repositoryName = parsed.repository?.name
	general.repositoryFullName = parsed.repository?.full_name
	general.received = new Date()/1000

	for change in parsed.push.changes
		if !change.commits?
			log 'no commits in change'
			continue

		for commit in change.commits
			commitData = {}
			commitData.message = commit.message
			commitData.date = commit.date
			commitData.hash = commit.hash
			applyKeysToObject general, commitData

			# Get next id
			commitMaxId = Db.shared.get('commitMaxId') || 0
			commitMaxId++
			Db.shared.set 'commitMaxId', commitMaxId

			# Set commit data
			Db.shared.set 'commits', commitMaxId, commitData
			log 'Commit: '+commitData.message

			# Send notification
			Event.create
				unit: 'commit'
				text: 'Commit: '+general.repositoryName+': '+commit.message


applyKeysToObject = (source, target) !->
	for key, value of source
		target[key] = value