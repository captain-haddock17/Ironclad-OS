--  entrypoint.adb: Main function and its closest utilities.
--  Copyright (C) 2021 streaksu
--
--  This program is free software: you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published by
--  the Free Software Foundation, either version 3 of the License, or
--  (at your option) any later version.
--
--  This program is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU General Public License for more details.
--
--  You should have received a copy of the GNU General Public License
--  along with this program.  If not, see <http://www.gnu.org/licenses/>.

with Arch.APIC;
with Arch.GDT;
with Arch.Clocks;
with Arch.IDT;
with Arch.PIC;
with Arch.CPU;
with Devices.FB;
with Arch.Flanterm;
with Panic;
with Messages; use Messages;
with Memory.Physical;
with Arch.MMU;
with Devices.Serial;
with Arch.Limine;
with Main;

package body Arch.Entrypoint is
   --  Response is a pointer to a Memmap_Response.
   Memmap_Request : Limine.Request :=
      (ID       => Limine.Memmap_ID,
       Revision => 0,
       Response => System.Null_Address)
      with Export, Async_Writers;

   procedure Bootstrap_Main is
      Addr : System.Address;

      MemPonse : Limine.Memmap_Response
         with Import, Address => Memmap_Request.Response;
      Inner_MMap : constant Limine.Memmap_Entry_Arr (1 .. MemPonse.Count)
         with Import, Address => MemPonse.Entries;
      Type_Entry : Boot_Memory_Type;
      Idx : Natural := 0;
   begin
      --  Initialize architectural state first.
      GDT.Init;
      IDT.Init;
      Devices.Serial.Init_COM1;
      Devices.FB.Early_Init;
      Arch.Flanterm.Init;

      --  Translate the limine protocol into arch-agnostic structures.
      Limine.Translate_Proto;

      --  Translate the memory map.
      declare
         Memmap : Boot_Memory_Map (1 .. Natural (MemPonse.Count));
      begin
         for Ent of Inner_MMap loop
            case Ent.EntryType is
               when Limine.LIMINE_MEMMAP_USABLE =>
                  Type_Entry := Memory_Free;
               when Limine.LIMINE_MEMMAP_ACPI_RECLAIMABLE =>
                  Type_Entry := Memory_ACPI_Reclaimable;
               when Limine.LIMINE_MEMMAP_ACPI_NVS =>
                  Type_Entry := Memory_ACPI_NVS;
               when Limine.LIMINE_MEMMAP_KERNEL_AND_MODS =>
                  Type_Entry := Memory_Kernel;
               when others =>
                  Type_Entry := Memory_Reserved;
            end case;

            Idx := Idx + 1;
            Memmap (Idx) :=
               (Start   => To_Address (Integer_Address (Ent.Base)),
                Length  => Storage_Count (Ent.Length),
                MemType => Type_Entry);
         end loop;

         --  Initialize the allocators and MMU.
         Memory.Physical.Init_Allocator (Memmap);
         if not Arch.MMU.Init (Memmap) then
            Panic.Hard_Panic ("The VMM could not be initialized");
         end if;

         --  Enable dmesg buffers.
         Messages.Enable_Logging;

         --  Print the memory map, it is useful at times.
         Messages.Put_Line ("Physical memory map:");
         for E of Memmap loop
            Addr := E.Start + E.Length;
            Messages.Put_Line
               ("[" & E.Start'Image & " - " & Addr'Image & "] " &
                Boot_Memory_Type'Image (E.MemType));
         end loop;
      end;

      --  Initialize the core's LAPIC and system's IOAPIC, essential for
      --  handling interrupts and IPIs.
      PIC.Mask_All;
      APIC.Init_LAPIC;
      APIC.Init_Core_LAPIC;
      if not Arch.APIC.Init_IOAPIC then
         Panic.Hard_Panic ("Could not start IOAPIC");
      end if;

      --  Initialize some system timers for interval counting.
      Arch.Clocks.Initialize_Sources;

      --  Initialize other cores, and then jump to the freestanding main.
      Arch.CPU.Init_Cores;

      --  Hand it over to main.
      Main;
   exception
      when Constraint_Error =>
         Panic.Hard_Panic ("Uncatched exception on the arch entrypoint");
   end Bootstrap_Main;
end Arch.Entrypoint;
