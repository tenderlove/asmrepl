require "fiddle"

module ASMREPL
  class ThreadState
    def self.sizeof
      fields.length * Fiddle::SIZEOF_INT64_T
    end

    def self.malloc
      new Fiddle::Pointer.malloc sizeof
    end

    FLAGS = [
      ['CF', 'Carry Flag'],
      [nil, 'Reserved'],
      ['PF', 'Parity Flag'],
      [nil, 'Reserved'],
      ['AF', 'Adjust Flag'],
      [nil, 'Reserved'],
      ['ZF', 'Zero Flag'],
      ['SF', 'Sign Flag'],
      ['TF', 'Trap Flag'],
      ['IF', 'Interrupt Enable Flag'],
      ['DF', 'Direction Flag'],
      ['OF', 'Overflow Flag'],
      ['IOPL_H', 'I/O privilege level High bit'],
      ['IOPL_L', 'I/O privilege level Low bit'],
      ['NT', 'Nested Task Flag'],
      [nil, 'Reserved'],
    ]

    attr_reader :to_ptr

    def initialize buffer
      @to_ptr = buffer
    end

    def [] name
      idx = fields.index(name)
      return unless idx
      to_ptr[Fiddle::SIZEOF_INT64_T * idx, Fiddle::SIZEOF_INT64_T].unpack1("l!")
    end

    def []= name, val
      idx = fields.index(name)
      return unless idx
      to_ptr[Fiddle::SIZEOF_INT64_T * idx, Fiddle::SIZEOF_INT64_T] = [val].pack("l!")
    end

    def flags
      flags = read_flags
      f = []
      FLAGS.each do |abbrv, _|
        if abbrv && flags & 1 == 1
          f << abbrv
        end
        flags >>= 1
      end
      f
    end

    def to_s
      buf = ""
      display_registers.first(8).zip(display_registers.drop(8)).each do |l, r|
        buf << "#{l.ljust(3)}  #{sprintf("%#018x", self[l] & MAXINT)}"
        buf << "  "
        buf << "#{r.ljust(3)}  #{sprintf("%#018x", self[r] & MAXINT)}\n"
      end

      buf << "\n"

      other_registers.each do |reg|
        buf << "#{reg.ljust(7)}  #{sprintf("%#018x", self[reg] & MAXINT)}\n"
      end
      buf
    end

    def display_registers
      %w{ rax rbx rcx rdx rdi rsi rbp rsp r8 r9 r10 r11 r12 r13 r14 r15 }
    end

    def other_registers
      fields - display_registers
    end

    def self.build fields
      Class.new(ThreadState) do
        define_method(:fields) do
          fields
        end

        define_singleton_method(:fields) do
          fields
        end

        fields.each_with_index do |field, i|
          define_method(field) do
            to_ptr[Fiddle::SIZEOF_INT64_T * i, Fiddle::SIZEOF_INT64_T].unpack1("l!")
          end

          define_method("#{field}=") do |v|
            to_ptr[Fiddle::SIZEOF_INT64_T * i, Fiddle::SIZEOF_INT64_T] = [v].pack("l!")
          end
        end
      end
    end
  end
end
