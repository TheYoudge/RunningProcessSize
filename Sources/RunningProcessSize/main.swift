import Foundation

class Utility {
    private static func compatibleRun( _ process: Process, _ command: String )
        -> Bool
    {
        if #available( macOS 10.13, * )
        {
            process.executableURL = URL( fileURLWithPath: command )
            do
            {
                try process.run()
            }
            catch let error
            {
                print( "ERROR: " + error.localizedDescription )
                return false
            }
            return true
        }

        // macOS 10.12 and lower, deprecated
        process.launchPath = command
        process.launch()
        return true
    }

    static func commandRun( _ command: String, _ arguments: [String] ) -> String?
    {
        let process = Process()
        process.arguments = arguments
        let pipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = pipe
        process.standardError = errorPipe

        guard Utility.compatibleRun( process, command )
        else
        {
            return nil
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        let successCode = 0
        if ( process.terminationStatus == successCode )
        {
            return String( data: data, encoding: .utf8 )
        }
        else
        {
            print( "ERROR: " + ( String( data: errorData, encoding: .utf8 )
                                    ?? "unknown" ) )
            return nil
        }
    }

    static func getFileSize( _ path: String ) -> Int
    {
        let url = URL( fileURLWithPath: path )
        var size: Int;
        do
        {
            let resKeys = try url.resourceValues( forKeys: [.fileSizeKey] )
            size = resKeys.fileSize!
        }
        catch
        {
            size = 0
        }
        return size;
    }

    static func printUsage()
    {
        print( """
               USAGE: RunningProcessSize <num>[s/m/h]

               WARNING: entering 2h+ will take a while to parse...

               """ )
    }

    static func getAndValidatePeriodFromArguments() -> String
    {
        let arguments = CommandLine.arguments
        if ( arguments.count != 2 )
        {
            Utility.printUsage()
            return ""
        }
        return arguments[1]
    }
}

struct LogEntry : Decodable
{
    let traceID: Int
    let processImagePath: String?
    let processID: Int
}

class LogExtractor
{
    static func getLastLogForPeriod( _ period: String ) -> [LogEntry]
    {
        let command = "/usr/bin/log"
        let arguments = ["show", "--last", period, "--style=json"]

        guard let output = Utility.commandRun( command, arguments ) else
        {
            return []
        }

        let data = output.data( using: .utf8 )!
        var logData: [LogEntry]

        do
        {
            logData = try JSONDecoder().decode( [LogEntry].self, from: data )
        }
        catch let error
        {
            print( error.localizedDescription )
            return []
        }

        return logData
    }
}

struct ProcessMeta
{
    var processImageSize: Int
    var processID: [Int]
}

class LogProcessor
{
    static func generateProcessList( _ logData: [LogEntry] )
        -> [String : ProcessMeta]
    {
        var processData: [String : ProcessMeta] = [:]
        for logItem in logData
        {
            let path = logItem.processImagePath ?? ""
            if ( path.count == 0 )
            {
                continue
            }

            if ( processData[path] == nil )
            {
                let fileSize = Utility.getFileSize( path )
                processData[path] = ProcessMeta( processImageSize: fileSize,
                                                 processID: [logItem.processID])
            }
            else
            {
                if( !processData[path]!.processID.contains( logItem.processID ))
                {
                    processData[path]!.processID.append( logItem.processID )
                }
            }
        }
        return processData
    }
}

class ProcessView
{
    private static func pumpSpaces( _ item: String, _ minColumnWidth: Int )
        -> String
    {
        var niceItem = item;
        while niceItem.count < minColumnWidth
        {
            niceItem.append( " " )
        }
        return niceItem
    }

    static func display( _ processData: [ String : ProcessMeta ] )
    {
        let c1Width = 25
        let c2Width = 50

        print( "" )

        print( pumpSpaces( " ProcessIDs", c1Width )
                + " "
                + pumpSpaces( "ProcessImage", c2Width )
                + " "
                + "ProcessImageSize" )

        var line = ""
        let lineWidth = c1Width + c2Width + c1Width
        while line.count < lineWidth
        {
            line.append( "-" )
        }
        print( line )

        let sortedData = processData.sorted { return $0.key > $1.key }

        for item in sortedData
        {
            var PIDs = ""
            for pid in item.value.processID
            {
                PIDs.append( " \(pid)" )
            }

            print( pumpSpaces( PIDs, c1Width )
                    + " "
                    + pumpSpaces( item.key, c2Width )
                    + " "
                    + "\( item.value.processImageSize )" )
        }
        print( "" )
    }
}

func main()
{
    let period = Utility.getAndValidatePeriodFromArguments()
    if ( period == "" )
    {
        return
    }

    let logOutput = LogExtractor.getLastLogForPeriod( period )

    let processList = LogProcessor.generateProcessList( logOutput )

    if( processList.count != 0 )
    {
        ProcessView.display( processList )
    }
}

main()
