#!/bin/bash

mail_file=$(sed '/X-Cron-Env/d' /var/spool/mail/"${USER}" | sed  '/From '"${USER}"'@spiedie81/d' | sed '/Return-Path: <'"${USER}"'@spiedie81/d' | sed '/X-Original-To: '"${USER}"'/d' | sed '/Delivered-To: '"${USER}"'@spiedie81/d' | sed '/Received: by spiedie81/d' | sed '/From: "(Cron Daemon)"/d' | sed 's/To: '"${USER}"'@spiedie81.*/#############################################################################################################################################/' | sed '/Content-Type: text/d' | sed '/Auto-Submitted/d' | sed '/Precedence: bulk/d' | sed '/Message-Id:/d' | sed "/id .*\;/d")

printf "%s\n" "${mail_file}"