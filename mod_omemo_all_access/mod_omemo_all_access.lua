-- OMEMO all access module
-- Copyright (c) 2017 Daniel Gultsch
--
-- This module is MIT/X11 licensed
--

local jid_bare = require "util.jid".bare;
local st = require "util.stanza"
local white_listed_namespace = "eu.siacs.conversations.axolotl."
local disco_feature_namespace = white_listed_namespace .. "whitelisted"

local mod_pep = module:depends"pep";
local pep_data = mod_pep.module.save().data;

module:add_feature(disco_feature_namespace)

function on_pep_request(event)
	local session, stanza = event.origin, event.stanza
	local payload = stanza.tags[1];
	if stanza.attr.type == 'get' then
		local node, requested_id;
		payload = payload.tags[1]
		if payload and payload.name == 'items' then
			node = payload.attr.node
			local item = payload.tags[1];
			if item and item.name == 'item' then
				requested_id = item.attr.id;
			end 
		end
		if node and string.sub(node,1,string.len(white_listed_namespace)) == white_listed_namespace then
			local user = stanza.attr.to and jid_bare(stanza.attr.to) or session.username..'@'..session.host;
			local user_data = pep_data[user];
			if user_data and user_data[node] then
				local id, item = unpack(user_data[node]);
				if not requested_id or id == requested_id then
					local stanza = st.reply(stanza)
						:tag('pubsub', {xmlns='http://jabber.org/protocol/pubsub'})
							:tag('items', {node=node})
								:add_child(item)
							:up()
						:up();
					session.send(stanza);
					module:log("debug","provided access to omemo node",node)
					return true;
					end
			end
			module:log("debug","requested node was white listed", node)
		end
	end
end

module:hook("iq/bare/http://jabber.org/protocol/pubsub:pubsub", on_pep_request, 10);
