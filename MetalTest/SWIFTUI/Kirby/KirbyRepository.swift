//
//  DataUtil.swift
//  SwiftUITest
//
//  Created by YUE on 2022/12/5.
//

typealias KirbyName = (name: String, jp: String, en: String)
typealias KirbyChara = (name: String, icon: String, url: String)
typealias KirbyGame = (name: String, icon: String, time: String, description: String)

class KirbyRepository {
    
    static let shared = KirbyRepository()
    
    private init() {
        
    }
    
    let kirbyName = KirbyName("星之卡比", "日语：星のカービィ","英语：Kirby")
    
    let logo = "logo"
    
    let description = "    星之卡比系列是HAL研究所和任天堂合力打造的动作平台游戏系列，以同名角色——外观类似粉红色小丸子的卡比为主角，它可以“吸入”（吞噬）敌人而获得敌人的能力，并借助这些能力进行闯关。"
    
    let charas = [
        KirbyChara("卡比", "charaBtn-kirby", "https://www.kirby.jp/character/kirby/"),
        KirbyChara("瓦豆鲁迪", "charaBtn-waddledee", "https://www.kirby.jp/character/waddle_dee/"),
        KirbyChara("金属骑士", "charaBtn-metaknight", "https://www.kirby.jp/character/meta_knight/"),
        KirbyChara("帝帝帝大王", "charaBtn-dedede", "https://www.kirby.jp/character/dedede/"),
    ]
    
    let games = [
        KirbyGame(
            name: "星之卡比 Wii 豪華版",
            icon: "game_1",
            time: "發售日 2023/2/24",
            description: "變得更豪華的《星之卡比 Wii》在Nintendo Switch登場！於2011年發售的《星之卡比 Wii》在Nintendo Switch上重生。以嶄新的圖像，卡比與同伴們一起享受最多4人的冒險。"
        ),
        KirbyGame(
            name: "卡比的美食節",
            icon: "game_2",
            time: "發售日 2022/8/17",
            description: "滾來滾去，吃東西，變大。在點心世界進行貪吃美食戰鬥！4個卡比彼此較量吃下的草莓數量的對戰動作遊戲。一邊滾動一邊前進的卡比，吃下舞台上的草莓就會逐漸變大。最終體積最大的卡比為優勝者。"
        ),

        KirbyGame(
            name: "星之卡比 探索發現",
            icon: "game_3",
            time: "發售日 2022/3/25",
            description: "「星之卡比」的首款3D動作遊戲。「星之卡比」系列最新作的舞台，是融合了文明和大自然的未知「新世界」。吸入，吐出，飛翔，複製，在有立體縱深的3D關卡中，使用卡比的熟悉動作自由地來回探索冒險。"
        ),
        KirbyGame(
            name: "卡比群星戰2",
            icon: "game_4",
            time: "發售日 2020/9/24",
            description: "卡比們加入了最多4人的同時對戰大亂鬥！可使用17種複製能力，並從5人的搭檔中選擇其中一位鬥士。靈活使用技能和道具，把對手的體力變成0後爲之勝利！"
        ),
        KirbyGame(
            name: "超級卡比獵人隊",
            icon: "game_5",
            time: "發售日 2019/9/5",
            description: "和好友一起進行超級戰鬥！4人卡比協力對抗巨大的敵人的「卡比獵人」，變得超級後在Nintendo Switch上登場！充滿個性的4種職業的卡比們組成隊伍，向自誇力量是BOSS級的強敵宣戰。迎接你的故事探索多達100種以上。"
        ),
        KirbyGame(
            name: "星之卡比 新星同盟",
            icon: "game_6",
            time: "發售日 2018/4/3",
            description: "「星之卡比」的最新作已經在Nintendo Switch上登場。這次增加了卡比投擲愛心，將敵人變成同伴的新功能。卡比將同伴換來換去，4人合作一起冒險！"
        ),
    ]
}


