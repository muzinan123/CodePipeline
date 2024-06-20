# (c) 2019 Amazon Web Services, Inc. or its affiliates.  All Rights
# Reserved. This AWS Content is provided subject to the terms of the
# AWS Customer Agreement available at http://aws.amazon.com/agreement
# or other written agreement between Customer and Amazon Web Services,
# Inc.


"""test_lambda_handler module

This module demonstrates example unit tests for the 'index' module.
"""


import json
import logging
import unittest
import src.main as main


logger = logging.getLogger()
logger.setLevel(logging.INFO)


class TestLambdaHandlerCase(unittest.TestCase):

    def test_lambda_handler_response(self):
        """Testing the lambda_handler response.

        Keyword arguments:
        self -- TestLambdaHandlerCase
        """
        result = main.lambda_handler(event=None, context=None)

        logger.info('Test: statusCode is equal to 200')
        self.assertEqual(result['statusCode'], 200)

        logger.info('Test: Content-Type is equal to application/json')
        self.assertEqual(result['headers']['Content-Type'], 'application/json')

        logger.info('Test: response body is an instance of class \'str\'')
        self.assertIsInstance(result['body'], str)

        logger.info('Test: \'example_message\' text string expected to be'
                    ' in the response body')
        self.assertIn('example_message', result['body'])

        logger.info('Test: response body can be deserialized into'
                    ' a Python object of type \'dict\'')
        self.assertIsInstance(json.loads(result['body']), dict)

        logger.info('Test: the \'message\' key in the JSON response'
                    ' equals to \'example_message\'')
        self.assertEqual(json.loads(result['body'])['message'],
                         'example_message')


if __name__ == '__main__':
    unittest.main()
