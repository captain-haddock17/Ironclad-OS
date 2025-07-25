--  arch-hpet.ads: Specification of the HPET driver.
--  Copyright (C) 2025 streaksu
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

with Interfaces; use Interfaces;

package Arch.HPET is
   --  Initialize the HPET, if found.
   --  @return True in Success, False on failure or not found.
   function Init return Boolean;

   --  Get resolution of the timer in nanoseconds, that is, the minimum amount
   --  of time the clock can measure.
   procedure Get_Resolution (Resolution : out Unsigned_64);

   --  Sleep an amount of nanoseconds.
   procedure NSleep (Nanoseconds : Unsigned_64);
end Arch.HPET;
