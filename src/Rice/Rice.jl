module Rice

export decode_aec, decode_rice, decode_rice_inv

function decode_aec(d, J = 16, n = 11; start_byte = 1)
    done = false
    i_byte = start_byte
    consumed_bits = 0
    samples = []
    while !done

        if consumed_bits >= 8
            i_byte += 1
            consumed_bits -= 8
        end

        if i_byte === length(d)
            b = (d[i_byte] << consumed_bits)
        else
            b = (d[i_byte] << consumed_bits) | (d[i_byte + 1] >> (8 - consumed_bits))
        end
        @info string(b, base = 2, pad = 8)

        if (b >> 3) === 0b00000
            # Zero Block
            @info "Zero Block" i_byte consumed_bits
            consumed_bits += 5

            counter = 0
            while true
                if consumed_bits >= 8
                    i_byte += 1
                    consumed_bits -= 8
                end

                if i_byte === length(d)
                    b = (d[i_byte] << consumed_bits)
                else
                    b = (d[i_byte] << consumed_bits) | (d[i_byte + 1] >> (8 - consumed_bits))
                end

                if counter > 63
                    error("impossible FS $counter")
                end

                if (b >> 7) === 0b1
                    consumed_bits += 1
                    break
                elseif (b >> 7) === 0b0
                    counter += 1
                    consumed_bits += 1
                else
                    error("WTF")
                end
            end

            if counter < 4
                counter += 1
            elseif counter === 4
                counter = 64
            elseif counter > 4
            else
                error("weird counter $counter")
            end

            @info repeat([0], counter * J) counter
            push!(samples, repeat([0], counter * J)...)

        elseif (b >> 3) === 0b00001
            # Second Extension
            @info "Second Extension" i_byte consumed_bits
            consumed_bits += 5
            error("not implemented")

        elseif (b >> 4) === 0b1111
            # No Compression
            @info "No Compression" i_byte consumed_bits
            consumed_bits += 4

            if consumed_bits >= 8
                i_byte += 1
                consumed_bits -= 8
            end

            if i_byte === length(d)
                b = (d[i_byte] << consumed_bits)
            else
                b = (d[i_byte] << consumed_bits) | (d[i_byte + 1] >> (8 - consumed_bits))
            end

            sample = Int(b) << (n - 8)
            consumed_bits += 8

            if consumed_bits >= 8
                i_byte += 1
                consumed_bits -= 8
            end

            if i_byte === length(d)
                b = (d[i_byte] << consumed_bits)
            else
                b = (d[i_byte] << consumed_bits) | (d[i_byte + 1] >> (8 - consumed_bits))
            end

            sample += Int(b) >> (16 - n)
            consumed_bits += 16 - n

            @info sample
            push!(samples, sample)

        else
            k = Int(b >> 4) - 1
            @info "Split Sample" i_byte consumed_bits k
            consumed_bits += 4

            for j in 1:J

                counter = 0
                while true
                    if consumed_bits >= 8
                        i_byte += 1
                        consumed_bits -= 8
                    end

                    if i_byte === length(d)
                        b = (d[i_byte] << consumed_bits)
                    else
                        b = (d[i_byte] << consumed_bits) | (d[i_byte + 1] >> (8 - consumed_bits))
                    end

                    if counter > 2^n - 1
                        error("impossible FS $counter")
                    end

                    if (b >> 7) === 0b1
                        consumed_bits += 1
                        break
                    elseif (b >> 7) === 0b0
                        counter += 1
                        consumed_bits += 1
                    else
                        error("WTF")
                    end
                end

                val = 0
                for i in 1:k
                    if consumed_bits >= 8
                        i_byte += 1
                        consumed_bits -= 8
                    end

                    if i_byte === length(d)
                        b = (d[i_byte] << consumed_bits)
                    else
                        b = (d[i_byte] << consumed_bits) | (d[i_byte + 1] >> (8 - consumed_bits))
                    end

                    val = (val << 1) + (b >> 7)
                    consumed_bits += 1
                end

                sample = counter * (2^k) + val
                @info sample k counter val
                push!(samples, sample)

                if sample > 2^n
                    error("impossible value $sample")
                end
            end

        end

        if i_byte === length(d)
            @info "end almost reached" i_byte consumed_bits
        end

    end
    samples
end

function decode_rice(d, k = 4, n = 11; start_byte = 1)
    done = false
    i_byte = start_byte
    consumed_bits = 0
    samples = []
    while !done
        counter = 0
        while true
            if consumed_bits >= 8
                i_byte += 1
                consumed_bits -= 8
            end

            if i_byte === length(d)
                b = (d[i_byte] << consumed_bits)
            elseif i_byte > length(d)
                @info "end overshot" i_byte consumed_bits string(d[i_byte-1], base = 2, pad = 8)
                return samples
            else
                b = (d[i_byte] << consumed_bits) | (d[i_byte + 1] >> (8 - consumed_bits))
            end

            if counter > 2^n - 1
                error("impossible FS $counter")
            end

            if (b >> 7) === 0b1
                consumed_bits += 1
                break
            elseif (b >> 7) === 0b0
                counter += 1
                consumed_bits += 1
            else
                error("WTF")
            end
        end

        val = 0
        for i in 1:k
            if consumed_bits >= 8
                i_byte += 1
                consumed_bits -= 8
            end

            if i_byte === length(d)
                b = (d[i_byte] << consumed_bits)
            elseif i_byte > length(d)
                @info "end overshot" i_byte consumed_bits string(d[i_byte-1], base = 2, pad = 8)
                return samples
            else
                b = (d[i_byte] << consumed_bits) | (d[i_byte + 1] >> (8 - consumed_bits))
            end

            val = (val << 1) + (b >> 7)
            consumed_bits += 1
        end

        sample = counter * (2^k) + val
        @info sample k counter val
        push!(samples, sample)

        if sample > 2^n
            error("impossible value $sample")
        end

        if i_byte === length(d)
            @info "end almost reached" i_byte consumed_bits string(d[i_byte], base = 2, pad = 8)
            break
        end

    end

    @info "end reached" i_byte consumed_bits string(d[i_byte], base = 2, pad = 8)
    return samples
end

function decode_rice_inv(d, k = 4, n = 11; start_byte = 1)
    done = false
    i_byte = start_byte
    consumed_bits = 0
    samples = []
    while !done
        while i_byte <= length(d)
            counter = 0
            while true
                if consumed_bits >= 8
                    i_byte += 1
                    consumed_bits -= 8
                end

                if i_byte === length(d)
                    b = (d[i_byte] << consumed_bits)
                else
                    b = (d[i_byte] << consumed_bits) | (d[i_byte + 1] >> (8 - consumed_bits))
                end

                if counter > 2^n - 1
                    error("impossible FS $counter")
                end

                if (b >> 7) === 0b0
                    consumed_bits += 1
                    break
                elseif (b >> 7) === 0b1
                    counter += 1
                    consumed_bits += 1
                else
                    error("WTF")
                end
            end

            val = 0
            for i in 1:k
                if consumed_bits >= 8
                    i_byte += 1
                    consumed_bits -= 8
                end

                if i_byte === length(d)
                    b = (d[i_byte] << consumed_bits)
                else
                    b = (d[i_byte] << consumed_bits) | (d[i_byte + 1] >> (8 - consumed_bits))
                end

                val = (val << 1) + (b >> 7)
                consumed_bits += 1
            end

            sample = counter * (2^k) + val
            @info sample k counter val
            push!(samples, sample)

            if sample > 2^n
                error("impossible value $sample")
            end
        end

        if i_byte === length(d)
            @info "end almost reached" i_byte consumed_bits
        end

    end
    samples
end

end  # module Rice
