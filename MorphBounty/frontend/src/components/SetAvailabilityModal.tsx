"use client";
import {
  AlertDialog,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from "@/components/ui/alert-dialog";
import { useEffect } from "react";
import {
  bookingAbi,
  bookingAddress,
  tokenAbi,
  tokenAddress,
} from "@/constants";
import { toast } from "sonner";
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from "@/components/ui/form";

import { useWaitForTransactionReceipt, useWriteContract } from "wagmi";
import { z } from "zod";
import { zodResolver } from "@hookform/resolvers/zod";
import { useForm } from "react-hook-form";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { MoveLeft } from "lucide-react";
import { parseUnits } from "viem";

interface InvestModalProps {
  children: React.ReactNode;
}

const SetAvailabilityModal = ({ children }: InvestModalProps) => {
  const {
    data: hash,
    error,
    isPending,
    writeContractAsync,
  } = useWriteContract();

  const { isLoading: isConfirming, isSuccess: isConfirmed } =
    useWaitForTransactionReceipt({
      hash,
    });

  useEffect(() => {
    if (isConfirming) {
      toast.loading("Transaction Pending");
    }
    if (isConfirmed) {
      toast.success("Transaction Successful", {
        action: {
          label: "View on Etherscan",
          onClick: () => {
            window.open(`https://explorer-holesky.morphl2.io/tx/${hash}`);
          },
        },
      });
    }
    if (error) {
      toast.error("Transaction Failed");
    }
  }, [isConfirming, isConfirmed, error, hash]);

  const formSchema = z.object({
    category: z.any(),
    price: z.any(),
  });

  const form = useForm<z.infer<typeof formSchema>>({
    resolver: zodResolver(formSchema),
    defaultValues: {
      roomId: 0,
      isAvailable: 0,
    },
  });

  const SetAvailability = async (data: z.infer<typeof formSchema>) => {
    console.log(data);
    const boolValue: boolean = data.isAvailable ? true : false;
    try {
      const setAvailabilityTx = await writeContractAsync({
        address: bookingAddress,
        abi: bookingAbi,

        functionName: "setRoomAvailability",
        args: [data.roomId, boolValue],
      });

      console.log("room transaction hash:", setAvailabilityTx);
    } catch (err: any) {
      toast.error("Transaction Failed: " + err.message);
      console.log("Transaction Failed: " + err.message);
    }
  };

  return (
    <AlertDialog>
      <AlertDialogTrigger asChild>{children}</AlertDialogTrigger>
      <AlertDialogContent>
        <AlertDialogHeader>
          <AlertDialogTitle>
            <div className="flex items-center gap-6 justify-center">
              <AlertDialogCancel className="border-none">
                <MoveLeft size={24} />
              </AlertDialogCancel>
              <h1>Set Room Availability</h1>
            </div>
          </AlertDialogTitle>
        </AlertDialogHeader>
        <div>
          <Form {...form}>
            <form onSubmit={form.handleSubmit(SetAvailability)} className="space-y-8">
              <FormField
                control={form.control}
                name="roomId"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel className="">
                      <h1 className="text-[#32393A]">Room Id</h1>
                    </FormLabel>
                    <FormControl>
                      <Input
                        className="rounded-full"
                        type="number"
                        placeholder="0"
                        {...field}
                      />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <FormField
                control={form.control}
                name="isAvailable"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel className="">
                      <h1 className="text-[#32393A]">is Available? (1: YES , 0: NO)</h1>
                    </FormLabel>
                    <FormControl>
                      <Input
                        className="rounded-full"
                        type="number"
                        placeholder="0"
                        {...field}
                      />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <Button
                className="bg-[#007A86] self-center my-8 rounded-full w-full"
                size="lg"
                disabled={isPending}
                type="submit"
              >
                {isPending ? "Loading" : "Submit"}
              </Button>
            </form>
          </Form>
        </div>
        <AlertDialogFooter className="mt-4">
          <AlertDialogCancel>Cancel</AlertDialogCancel>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  );
};

export default SetAvailabilityModal;
