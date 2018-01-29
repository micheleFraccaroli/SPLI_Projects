function socket_BA(host, port)
    
    import java.net.*
    import java.io.*
    
    server_socket = [];
    input_socket = [];
    try
        fprintf("\nTry to connect to host with port &d\n", port);

        server_socket = ServerSocket(port);
        input_socket = server_socket.accept;

        fprintf("\n...Connected with host...\n");

        input_stream = input_socket.getInputStream;
        d_input_stream = DataInputStream(input_stream);

        %lettura da socket, se non va fai un ciclo e prendi byte per
        %byte e mettili in una riga di zeri: [msg = zeros(1, bytes_available, 'uint32')]
        bytes_available = input_stream.available;
        data_reader = DataReader(d_input_stream);
        message = data_reader.readBuffer(bytes_available);

        message = char(message);
    catch
        if ~isempty(server_socket)
            server_socket.close
        end
        if ~isempty(output_socket)
            output_socket.close
        end
    end
end
    
    
        