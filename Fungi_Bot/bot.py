import telebot
import tensorflow as tf
import numpy as np
import os
from dotenv import load_dotenv
load_dotenv()
key = os.getenv('API_KEY')
bot = telebot.TeleBot(key)
model = tf.keras.models.load_model('fungi_m.h5')
class_names = ['съедобен', 'несъедобен']

@bot.message_handler(commands=['start'])
def welcome(message):
        markup = telebot.types.ReplyKeyboardMarkup(resize_keyboard=True)
        start = telebot.types.KeyboardButton('/start')
        help = telebot.types.KeyboardButton('/help')
        markup.row(start, help)
        bot.send_sticker(message.chat.id, 'CAACAgIAAxkBAAMMZGqMcVDVV3xYjuawl7xXS3mcIS4AAq8AAwS9HhmFFm9jW5iI9y8E',
                         reply_markup=markup)

@bot.message_handler(commands=['help'])
def help_c(message):
    bot.send_message(message.chat.id, 'Чтобы начать работу, пришлите фото гриба и я попробую угадать можно ли его есть.')


@bot.message_handler(content_types=['photo'])
def photo(message):
    photo_id = message.photo[-1].file_id
    photo_info = bot.get_file(photo_id)
    img = bot.download_file(photo_info.file_path)
    img = tf.image.decode_jpeg(img)
    img = tf.image.resize(img, [200, 200])
    img_array = tf.keras.utils.img_to_array(img)
    img_array = tf.expand_dims(img_array, 0)
    predictions = model.predict(img_array)
    score = tf.nn.softmax(predictions[0])
    bot.send_message(message.chat.id, "С вероятностью, равной {:.2f}%, я могу предположить, что этот гриб {}."
                     .format(100 * np.max(score), class_names[np.argmax(score)]))

bot.polling(none_stop=True)
