/*
 * Project:     macyac
 * File:        macyac.m
 * Author:      Andrew Wellington <proton[at]wiretapped.net>
 *
 * License:
 * Copyright (C) 2004 Andrew Wellington.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Foundation/Foundation.h>
#import "../../Common/Source/GrowlDefines.h"

#include <sys/types.h>
#include <sys/socket.h>
#include <sys/wait.h>

#include <netinet/in.h>
#include <signal.h>
#include <stdio.h>
#include <strings.h>
#include <unistd.h>

#define DEFAULT_YAC_PORT 10629
#define MAX_BACKLOG 10

static int port = DEFAULT_YAC_PORT;
static int sticky = 0;

static void usage(char *argv[])
{
	fprintf(stderr, "Usage: %s [-h] [-s] [-p port]\n", argv[0]);
    fprintf(stderr, "-h: display this help message\n");
	fprintf(stderr, "-p: port to listen to for incoming Yac messages\n");
	fprintf(stderr, "-s: make notifications sticky\n");
	exit(EXIT_FAILURE);
}

static void getoptions(int argc, char *argv[])
{
	int ch;

	while ((ch = getopt(argc, argv, "p:hs")) != -1)
		switch (ch) {
			case 'h':
				usage(argv);
				break;
            case 's':
				sticky = 1;
				break;
			case 'p':
				port = strtol(optarg, (char **)NULL, 10);
				if (port == 0)
					usage(argv);
				break;
			case '?':
			default:
				usage(argv);
		}
	argc -= optind;
	argv += optind;
}

static void growl_notify (NSString *title, NSString *content)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSDistributedNotificationCenter *distCenter = [NSDistributedNotificationCenter defaultCenter];
	NSDictionary *userInfo;
	NSNumber *stick;

	/* register with Growl. */
	NSArray *defaultAndAllNotifications = [[NSArray alloc] initWithObjects:@"Incoming Caller", @"Network Message", nil];
	userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:
		@"MacYac",                  GROWL_APP_NAME,
		defaultAndAllNotifications, GROWL_NOTIFICATIONS_ALL,
		defaultAndAllNotifications, GROWL_NOTIFICATIONS_DEFAULT,
		nil];
	[defaultAndAllNotifications release];
	[distCenter postNotificationName:GROWL_APP_REGISTRATION
							  object:nil
							userInfo:userInfo];
	[userInfo release];

	/* and send notification */
	stick = [[NSNumber alloc] initWithInt:sticky];
	userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:
		title, GROWL_NOTIFICATION_NAME,
		@"MacYac", GROWL_APP_NAME,
		title,     GROWL_NOTIFICATION_TITLE,
		content,   GROWL_NOTIFICATION_DESCRIPTION,
		stick,     GROWL_NOTIFICATION_STICKY,
		nil];
	[stick release];
	[distCenter postNotificationName:GROWL_NOTIFICATION
							  object:nil
							userInfo:userInfo];
	[userInfo release];

	[pool release];
}

static void yac_read(int client)
{
	int len = 0, bytes_read;
	int exit_flag = 0;
	int i;
	char inbuf[301];

	/* read for max 300 characters, or until null */
	while (len < 300 && !exit_flag) {
		bytes_read = read(client, inbuf + len, 300 - len);
		if (bytes_read == -1 || bytes_read == 0)
			break;

		len += bytes_read;

		for (i = 0; i < len; i++) {
			if (inbuf[i] == '\0') {
				exit_flag = 1;
				break;
			}
		}
	}
	/* ensure we're null terminated if we hit 300 limit */
	inbuf[len] = '\0';

	char caller[296];
	char number[296];
	NSString *title;
	NSString *content;
	if (sscanf(inbuf, "@CALL%[^~]~%300c", caller, number) < 2) {
		/* didn't convert right */
		title = @"Network Message";
		content = [[NSString alloc] initWithUTF8String:inbuf];
	} else {
		title = @"Incoming Caller";
		content = [[NSString alloc] initWithFormat:@"%s\n%s", caller, number];
	}
	growl_notify(title, content);
	[content release];
}

/* keep your brain safe: avoid zombies */
static void chld_handler (int signum)
{
	int status;

	if (signum != SIGCHLD)
		return;

	wait3(&status, WNOHANG, NULL);
}

int main (int argc, char *argv[])
{
	int sock;
	int client;
	int optval;
	struct sockaddr_in addr;

	getoptions(argc, argv);

	/* setup socket */
	sock = socket(AF_INET, SOCK_STREAM, 0);
	if (sock == -1) {
		perror("socket");
		exit(EXIT_FAILURE);
	}

	optval = 1;
	if (setsockopt(sock, SOL_SOCKET, SO_REUSEADDR, &optval, sizeof(optval)) < 0) {
		perror("setsockopt");
		exit(EXIT_FAILURE);
	}

	bzero(&addr, sizeof(addr));
	addr.sin_len = sizeof(addr);
	addr.sin_family = AF_INET;
	addr.sin_port = htons(port);
	addr.sin_addr.s_addr = INADDR_ANY;

	if (bind(sock, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
		perror("bind");
		exit(EXIT_FAILURE);
	}

	if (listen(sock, MAX_BACKLOG) < 0) {
		perror("listen");
		exit(EXIT_FAILURE);
	}

    /* Become a daemon */
    switch (fork()) {
		case -1:
			/* error */
			perror("fork");
			exit(EXIT_FAILURE);
			break;
		case 0:
			/* child process, becomes daemon */
			close(STDIN_FILENO);
			close(STDOUT_FILENO);
			close(STDERR_FILENO);
			/* request a new session (job control) */
			if (setsid() == -1)
				exit(EXIT_FAILURE);
			break;
		default:
			/* parent returns to calling process */
			return 0;
	}

	if (signal(SIGCHLD, chld_handler) == SIG_ERR) {
		perror("signal");
		exit(EXIT_FAILURE);
	}

	/* infinite loop accepting connections */
	while (1) {
		socklen_t len = sizeof(addr);
		client = accept(sock, (struct sockaddr *)&addr, &len);
		if (client < 0) {
			perror("accept");
			continue;
		}

		switch (fork()) {
			case 0:
				/* child */
				yac_read(client);
				exit(EXIT_SUCCESS);
				break;
			case -1:
				/* error */
				perror("fork");
				break;
			default:
				/* parent */
				close(client);
				/* get back to processing */
				break;

		}

	}
}
