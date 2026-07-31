#!/usr/bin/python
# -*- coding: utf-8 -*-

import msgpackrpc
from msgpackrpc.error import CallError

class GMRPClient(msgpackrpc.Client):

	def init(self):
		self.name = ''
		self.sessionID = None

	def _result_handler(self, result):
		# print('_result_handler', result)
		ret, msg, kwargs = result
		if not ret:
			raise GMTaskError(msg, **kwargs)
		return msg

	def call_slient(self, method, *args):
		if self.sessionID is not None:
			args = (self.name, self.sessionID) + args

		result = self.send_request(method, args).get()
		ret = self._result_handler(result)

		return ret

	def call(self, method, *args):
		if self.sessionID is not None:
			args = (self.name, self.sessionID) + args

		ret = None
		try:
			result = self.send_request(method, args).get()
			ret = self._result_handler(result)

		except Exception as e:
			raise e

		return ret

	def call_async(self, method, *args):
		if self.sessionID is not None:
			args = (self.name, self.sessionID) + args

		fu = self.send_request(method, args)
		fu.attach_result_handler(self._result_handler)
		return fu


class GMTaskReturn(object):

	def __init__(self, msg, **kwargs):
		self.msg = msg
		self.kwargs = kwargs

	def to_msgpack(self):
		return (True, self.msg, self.kwargs)

class GMTaskError(CallError):
	CODE = ".GMTaskError"

	def to_msgpack(self):
		return (False, self.msg, self.kwargs)
