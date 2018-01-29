function socket_AB(host, port, dim, message)
    
    import java.net.*;
    import java.io.*;
    
    output_socket = [];

    try
        fprintf("dim: %d\n", dim);
        fprintf("\nTry to connect to host with port %d\n", port);

        out_socket = Socket(host,port);
        fprintf("\nConnesso a %s\n", host);
        
        % mando il criptato a B
        output_socket = out_socket.getOutputStream;
        d_output_stream = DataOutputStream(output_socket);
        
        d_output_stream.writeInt(dim);
        
        fprintf("\nInvio dim-----> %d\n", dim);
        d_output_stream.write(message);
        d_output_stream.flush;
        
        
    catch
        if ~isempty(out_socket)
            out_socket.close;
        end
    end
end