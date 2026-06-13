package com.choicemod.common.packet;

import com.choicemod.ChoiceMod;
import com.choicemod.common.event.ChoiceApplier;
import com.choicemod.common.registry.ChoiceRegistry;
import net.fabricmc.fabric.api.networking.v1.PayloadTypeRegistry;
import net.fabricmc.fabric.api.networking.v1.ServerPlayNetworking;
import net.minecraft.network.PacketByteBuf;
import net.minecraft.network.codec.PacketCodec;
import net.minecraft.network.packet.CustomPayload;
import net.minecraft.server.network.ServerPlayerEntity;
import net.minecraft.util.Identifier;

public class ChoicePackets {

    // Сервер → Клиент: показать экран выбора
    public static final CustomPayload.Id<ShowChoicePayload> SHOW_CHOICE_ID =
            new CustomPayload.Id<>(Identifier.of(ChoiceMod.MOD_ID, "show_choice"));

    // Клиент → Сервер: игрок выбрал пакет (0 = левый, 1 = правый)
    public static final CustomPayload.Id<PlayerChoicePayload> PLAYER_CHOICE_ID =
            new CustomPayload.Id<>(Identifier.of(ChoiceMod.MOD_ID, "player_choice"));

    public static void registerServerPackets() {
        // Регистрируем codec для ShowChoicePayload (сервер → клиент)
        PayloadTypeRegistry.playS2C().register(ShowChoicePayload.ID, ShowChoicePayload.CODEC);

        // Регистрируем codec для PlayerChoicePayload (клиент → сервер)
        PayloadTypeRegistry.playC2S().register(PlayerChoicePayload.ID, PlayerChoicePayload.CODEC);

        // Обработчик выбора на сервере
        ServerPlayNetworking.registerGlobalReceiver(PlayerChoicePayload.ID,
                (payload, context) -> {
                    ServerPlayerEntity player = context.player();
                    int choiceIndex = payload.choiceIndex();
                    context.server().execute(() -> {
                        ChoiceApplier.applyChoice(player, choiceIndex);
                    });
                });
    }

    // ─── Payload: сервер показывает экран выбора ───────────────────────────
    public record ShowChoicePayload(
            String leftTitle, String leftBonus, String leftPenalty,
            String rightTitle, String rightBonus, String rightPenalty,
            int timerSeconds
    ) implements CustomPayload {

        public static final Id<ShowChoicePayload> ID = SHOW_CHOICE_ID;

        public static final PacketCodec<PacketByteBuf, ShowChoicePayload> CODEC =
                PacketCodec.of(
                        (value, buf) -> {
                            buf.writeString(value.leftTitle);
                            buf.writeString(value.leftBonus);
                            buf.writeString(value.leftPenalty);
                            buf.writeString(value.rightTitle);
                            buf.writeString(value.rightBonus);
                            buf.writeString(value.rightPenalty);
                            buf.writeInt(value.timerSeconds);
                        },
                        buf -> new ShowChoicePayload(
                                buf.readString(), buf.readString(), buf.readString(),
                                buf.readString(), buf.readString(), buf.readString(),
                                buf.readInt()
                        )
                );

        @Override
        public Id<? extends CustomPayload> getId() { return ID; }
    }

    // ─── Payload: клиент отправляет выбор ──────────────────────────────────
    public record PlayerChoicePayload(int choiceIndex) implements CustomPayload {

        public static final Id<PlayerChoicePayload> ID = PLAYER_CHOICE_ID;

        public static final PacketCodec<PacketByteBuf, PlayerChoicePayload> CODEC =
                PacketCodec.of(
                        (value, buf) -> buf.writeInt(value.choiceIndex),
                        buf -> new PlayerChoicePayload(buf.readInt())
                );

        @Override
        public Id<? extends CustomPayload> getId() { return ID; }
    }
}
