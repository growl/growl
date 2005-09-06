/*
 * Copyright 2004-2005 The Growl Project.
 * Created by Jeremy Rossi <jeremy@jeremyrossi.com>
 * Released under the BSD license.
 */

#include <Python.h>
#import <Foundation/Foundation.h>

static PyObject * growl_PostDictionary(NSString *name, PyObject *self, PyObject *args) {
	char *key;
	const char *value;
	int i, j, size;

	PyObject *inputDict;
	PyObject *pKeys = NULL;
	PyObject *pKey, *pValue;

	NSMutableDictionary *note = [[NSMutableDictionary alloc] init];

	if (!PyArg_ParseTuple(args, "O!", &PyDict_Type, &inputDict))
		goto error;

	pKeys = PyDict_Keys(inputDict);
	for (i = 0; i < PyList_Size(pKeys); ++i) {
		NSString *convertedKey;

		/* Converting the PyDict key to NSString and used for key in note */
		pKey = PyList_GetItem(pKeys, i);
		if (!pKey)
			// Exception already set
			goto error;
		pValue = PyDict_GetItem(inputDict, pKey);
		if (!pValue) {
			// XXX Neeed a real Error message here.
			PyErr_SetString(PyExc_TypeError," ");
			goto error;
		}
		if (PyUnicode_Check(pKey)) {
			size = PyUnicode_GET_DATA_SIZE(pKey);
			value = PyUnicode_AS_DATA(pKey);
			convertedKey = [[NSString alloc] initWithBytes:value 
													length:size
												  encoding:NSUnicodeStringEncoding];
		} else if (PyString_Check(pKey)) {
			key = PyString_AsString(pKey);
			convertedKey = [[NSString alloc] initWithUTF8String:key];
		} else {
			PyErr_SetString(PyExc_TypeError,"The Dict keys must be strings/unicode");
			goto error;
		}

		/* Converting the PyDict value to NSString or NSData based on class  */
		if (PyString_Check(pValue)) {
			NSString *convertedValue = [[NSString alloc] initWithUTF8String:PyString_AS_STRING(pValue)];
			[note setObject:convertedValue forKey:convertedKey];
			[convertedValue release];
		} else if (PyInt_Check(pValue)) {
			NSNumber *convertedValue = [[NSNumber alloc] initWithLong:PyInt_AS_LONG(pValue)];
			[note setObject:convertedValue forKey:convertedKey];
			[convertedValue release];
		} else if (PyUnicode_Check(pValue)) {
			NSString *convertedValue = [[NSString alloc] initWithBytes:PyUnicode_AS_DATA(pValue)
													  length:PyUnicode_GET_DATA_SIZE(pValue)
													encoding:NSUnicodeStringEncoding];
			[note setObject:convertedValue forKey:convertedKey];
			[convertedValue release];
		} else if (pValue == Py_None) {
			NSData *data = [[NSData alloc] init];
			[note setObject:data forKey:convertedKey];
			[data release];
		} else if (PyList_Check(pValue)) {
			NSMutableArray *listHolder = [[NSMutableArray alloc] init];
			for (j = 0; j < PyList_Size(pValue); ++j) {
				PyObject *lValue = PyList_GetItem(pValue, j);
				if (PyString_Check(lValue)) {
					NSString *str = [[NSString alloc] initWithUTF8String:PyString_AS_STRING(lValue)];
					[listHolder addObject:str];
					[str release];
				} else if (PyUnicode_Check(lValue)) {
					NSString *convertedSubValue = [[NSString alloc] initWithBytes:PyUnicode_AS_DATA(pValue)
																 length:PyUnicode_GET_DATA_SIZE(lValue)
															   encoding:NSUnicodeStringEncoding];
					[listHolder addObject:convertedSubValue];
					[convertedSubValue release];
				} else {
					[convertedKey release];
					PyErr_SetString(PyExc_TypeError,"The lists must only contain strings");
					goto error;
				}
			}
			[note setObject:listHolder forKey:convertedKey];
			[listHolder release];
		} else if (PyObject_HasAttrString(pValue, "rawImageData")) {
			PyObject *lValue = PyObject_GetAttrString(pValue, "rawImageData");
			if (!lValue) {
				goto error;
			} else if (PyString_Check(lValue)) {
				NSData *convertedIcon = [[NSData alloc] initWithBytes:PyString_AsString(lValue)
													   length:PyString_Size(lValue)];
				[note setObject:convertedIcon forKey:convertedKey];
				[convertedIcon release];
			} else {
				[convertedKey release];
				PyErr_SetString(PyExc_TypeError, "Icon with rawImageData attribute present must ensure it is a string.");
				goto error;
			}
		} else {
			[convertedKey release];
			PyErr_SetString(PyExc_TypeError, "Value is not of Str/List");
			goto error;
		}
		[convertedKey release];
	}

	Py_BEGIN_ALLOW_THREADS
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:name
																   object:nil 
																 userInfo:note
													   deliverImmediately:YES];
	[pool     release];
	[note     release];
	Py_END_ALLOW_THREADS

	Py_DECREF(pKeys);

	Py_INCREF(Py_None);
	return Py_None;

error:
	[note release];

	Py_XDECREF(pKeys);

	return NULL;
}

static PyObject * growl_PostRegistration(PyObject *self, PyObject *args) {
	return growl_PostDictionary(@"GrowlApplicationRegistrationNotification", self, args);
}

static PyObject * growl_PostNotification(PyObject *self, PyObject *args) {
	return growl_PostDictionary(@"GrowlNotification", self, args);
}

static PyMethodDef GrowlMethods[] = {
	{"PostNotification",  growl_PostNotification, METH_VARARGS, "Send a notification to GrowlHelperApp"},
	{"PostRegistration",  growl_PostRegistration, METH_VARARGS, "Send a registration to GrowlHelperApp"},
	{NULL, NULL, 0, NULL}		/* Sentinel */
};


PyMODINIT_FUNC init_growl(void) {
	Py_InitModule("_growl", GrowlMethods);
}
